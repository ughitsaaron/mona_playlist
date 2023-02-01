defmodule Mona.Scraper do
  use Agent
  @base_url "https://wfmu.org/"

  def start() do
    pid = spawn(fn -> :noop end)
    {:ok, pid}
  end

  defp to_path(path), do: Path.join([@base_url, path])

  defp fetch(path) do
    case to_path(path) |> HTTPoison.get() do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> Floki.parse_document!(body)
      {:ok, %HTTPoison.Response{status_code: 404}} -> {:error, "Not found"}
      {:error, %HTTPoison.Error{reason: reason}} -> {:error, reason}
    end
  end

  def get_date_and_href(node) do
    date = Floki.text(node) |> String.split(":") |> List.first() |> String.replace("\n", "")
    href = Floki.find(node, "a[href^=\"/playlist\"]") |> Floki.attribute("href") |> List.first()
    {date, href}
  end

  def find_playlists() do
    fetch("/playlists/M1")
    |> Floki.find(".showlist li")
    |> Enum.map(&get_date_and_href/1)
  end

  def fetch_playlist(url) do
    document = fetch(url)
    [_header | songs] = document |> Floki.find("#songs table tr") |> Enum.map(&Floki.children/1)

    playlist_title =
      document
      |> Floki.find("h2")
      |> Enum.take(1)
      |> Floki.text()
      |> String.replace("\n", " ")
      |> String.trim()

    tracks = Enum.map(songs, &parse_row/1) |> Enum.filter(& &1)
    {playlist_title, tracks}
  end

  defp parse_row([
         {"td", _, artist_node},
         {"td", _, title_node} | _
       ]) do
    artist = Floki.text(artist_node) |> sanitize()
    song_title = Floki.text(title_node) |> sanitize()
    {artist, song_title}
  end

  defp parse_row(_other), do: nil

  defp sanitize(str) do
    String.split(str, "\n")
    |> List.first()
    |> String.replace("Music behind DJ:", "")
    |> String.trim()
  end

  def init_scrape(nth \\ 0) do
    find_playlists()
    |> Enum.at(nth)
    |> fetch_playlist()
  end
end
