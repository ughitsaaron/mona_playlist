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

  defp find_playlists() do
    fetch("/playlists/M1")
    |> Floki.attribute("a[href^=\"/playlists\"]", "href")
  end

  defp fetch_playlist(url) do
    document = fetch(url)
    [_header | songs] = document |> Floki.find("#songs table tr") |> Enum.map(&Floki.children/1)

    title =
      document
      |> Floki.find("h2")
      |> Enum.take(1)
      |> Floki.text()
      |> String.replace("\n", " ")
      |> String.trim()

    track = Enum.map(songs, &parse_row/1) |> Enum.filter(& &1)
    {title, track}
  end

  defp parse_row([
         {"td", _, artist_node},
         {"td", _, title_node} | _
       ]) do
    Enum.map([artist_node, title_node], &sanitize/1)
  end

  defp parse_row(_other), do: nil

  defp sanitize(str) do
    Floki.text(str)
    |> String.split("\n")
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
