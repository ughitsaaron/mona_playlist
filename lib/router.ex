defmodule Mona.Router do
  alias Mona.Spotify
  use Plug.Router

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Poison
  )

  plug(:match)
  plug(:dispatch)

  def init(_opts) do
    Mona.Spotify.start_link()

    IO.puts("Authenticating with Spotify…")

    if System.find_executable("open") do
      System.cmd("open", ["http://localhost:4000"])
    end
  end

  defp redirect(conn, url) do
    conn
    |> put_resp_header("location", url)
    |> send_resp(conn.status || 302, "redirecting")
    |> halt()
  end

  get "/" do
    query_params =
      URI.encode_query(%{
        response_type: "code",
        client_id: "d5e3977ccb2a4f919c90b91932116a72",
        scope:
          Enum.join(
            [
              "user-read-private",
              "user-read-email",
              "playlist-modify-private",
              "playlist-modify-public"
            ],
            " "
          ),
        redirect_uri: "http://localhost:4000/auth/callback",
        state: "abcd1234"
      })

    redirect_path =
      "https://accounts.spotify.com/authorize"
      |> URI.parse()
      |> Map.put(:query, query_params)
      |> URI.to_string()

    redirect(conn, redirect_path)
  end

  get "/auth/callback" do
    {:ok, _pid} = Mona.Scraper.start()
    {nth, _} = System.get_env("NTH_EPISODE", "0") |> Integer.parse()
    {title, playlist} = Mona.Scraper.init_scrape(nth)

    Mona.Spotify.authorize(conn)

    :ok =
      Enum.map(
        playlist,
        fn item -> Mona.Spotify.search_track(item) end
      )
      |> Enum.reject(&is_nil/1)
      |> Spotify.create_playlist(title)

    conn |> send_resp(200, Poison.encode!(%{status: :ok})) |> halt()
  end

  match _ do
    send_resp(conn, 200, "hellloooo") |> halt()
  end
end
