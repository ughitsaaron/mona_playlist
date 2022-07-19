defmodule Mona.Scraper do
  alias IO.ANSI

  @base_url "https://wfmu.org/"

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
    |> Floki.attribute("div.showlist ul li a[href^=\"/playlists\"]", "href")
  end

  defp fetch_playlist(url) do
    [_header | songs] = fetch(url) |> Floki.find("#songs table tr") |> Enum.map(&Floki.children/1)
    Enum.map(songs, &parse_row/1) |> Enum.filter(& &1)
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
    |> String.replace("\n", "")
    |> String.replace("Music behind DJ:", "")
    |> String.trim()
  end

  def init(count \\ 1) do
    find_playlists()
    |> Enum.take(count)
    |> Enum.map(&fetch_playlist/1)
    |> Enum.each(&print/1)
  end

  defp print(text) do
    IO.inspect(ANSI.green())
    IO.inspect(text)
    IO.inspect(ANSI.reset())
  end
end
