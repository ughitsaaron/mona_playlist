defmodule Mona.Main do
  use Application

  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Mona.Router,
        options: [port: port()]
      )
    ]

    {:ok, _} =
      link = Supervisor.start_link(children, strategy: :one_for_one, name: Mona.Supervisor)

    main(nil)
    link
  end

  @spec select_playlist(list({String.t(), String.t() | :next})) :: {String.t(), String.t()}
  defp select_playlist([chunk | playlists]) do
    # Reached final chunk
    chunk = if Enum.empty?(playlists), do: Enum.drop(chunk, -1), else: chunk

    case Owl.IO.select(chunk,
           render_as: fn {title, _href} -> Owl.Data.tag(title, :green) end,
           label: "Please select a playlist to add to Spotify"
         ) do
      {_, :next} -> select_playlist(playlists)
      selection -> selection
    end
  end

  defp print_tracks(tracks) do
    Enum.map(tracks, fn {artist, title} -> %{"artist" => artist, "title" => title} end)
    |> Owl.Table.new(
      border_style: :double,
      padding_x: 2,
      render_cell: [
        header: fn header -> Owl.Data.tag(header, :magenta) end,
        body: fn data -> Owl.Data.tag(data, :green) end
      ]
    )
    |> Owl.IO.puts()
  end

  defp fetch_playlist(title, href) do
    [
      Owl.Data.tag("You selected: #{title}", :magenta),
      "\n",
      Owl.Data.tag("Fetching #{href}", :yellow)
    ]
    |> Owl.IO.puts()

    {_playlist_title, tracks} = Mona.Scraper.fetch_playlist(href)
    print_tracks(tracks)

    tracks
  end

  @spec main(any) :: any
  def main(_args) do
    Owl.Data.tag(["\n", "Fetching playlists…", "\n"], :yellow) |> Owl.IO.puts()

    {title, href} =
      Mona.Scraper.find_playlists()
      |> Enum.reject(fn {_date, href} -> is_nil(href) end)
      |> Enum.chunk_every(8)
      |> Enum.map(fn chunk -> Enum.concat(chunk, [{"See more playlists", :next}]) end)
      |> select_playlist()

    _tracks = fetch_playlist(title, href)

    case Owl.IO.confirm(
           message: Owl.Data.tag("Create a new Spotify playlist?", :magenta),
           default: true
         ) do
      true ->
        fn ->
          Owl.IO.puts(Owl.Data.tag("Authenticating to Spotify…", :magenta))
        end

      _ ->
        fn ->
          Owl.IO.puts(Owl.Data.tag("Exiting…", :red))
          Application.stop(:mona)
        end
    end

    nil
  end

  defp port, do: 4000
end
