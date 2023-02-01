defmodule Mona.Spotify do
  use Agent

  alias Mona.Spotify.Fetch
  alias HTTPoison.Response

  @endpoint "https://api.spotify.com"

  def process_request_url(%{subdomain: subdomain, path: path}) do
    String.replace(@endpoint, "api", subdomain) <> path
  end

  def process_request_url(path), do: @endpoint <> path

  def process_request_body(term), do: Poison.encode!(term)

  def process_response_body(body) do
    Poison.decode!(body)
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
  end

  defp open_browser(path) do
    cmd =
      case :os.type() do
        {:unix, :darwin} -> "open"
        _ -> :error
      end

    if System.find_executable(cmd) do
      System.cmd(cmd, [path])
    end
  end

  def start_link() do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def update_state(key, value) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))
  end

  def get_state(key) do
    Agent.get(__MODULE__, &Map.get(&1, key))
  end

  def authorize(conn) do
    auth = Fetch.authorize(conn)

    :ok = update_state(:access_token, auth.access_token)

    headers = [{"Authorization", "Bearer #{auth.access_token}"}]

    user =
      Fetch.get!("/v1/me", headers)
      |> Map.get(:body)

    :ok = update_state(:user_id, user.id)
    %{user_id: user.id, access_token: auth.access_token}
  end

  defp authorization_headers do
    access_token = get_state(:access_token)
    [{"Authorization", "Bearer #{access_token}"}]
  end

  def create_playlist(tracks, title) do
    user_id = get_state(:user_id)
    url = "https://api.spotify.com/v1/users/#{user_id}/playlists"
    headers = authorization_headers()
    body = Poison.encode!(%{name: title})

    playlist_id =
      case HTTPoison.post!(url, body, headers) do
        %Response{status_code: 201, body: body} -> Poison.decode!(body)["id"]
      end

    url = "https://api.spotify.com/v1/playlists/#{playlist_id}/tracks"
    body = Poison.encode!(%{uris: Enum.flat_map(tracks, &Map.values/1)})

    case HTTPoison.post!(url, body, headers) do
      %Response{status_code: 201} -> :ok
    end
  end

  def search_track([artist, track | _] = _) do
    search_params =
      URI.encode_query(%{
        q: "#{track} artist:#{artist}",
        type: "track",
        market: "US",
        limit: 1
      })

    search =
      "https://api.spotify.com/v1/search"
      |> URI.parse()
      |> Map.put(:query, search_params)
      |> URI.to_string()

    headers = authorization_headers()

    result =
      case HTTPoison.get!(search, headers) do
        %Response{status_code: 200, body: body} -> Poison.decode!(body)
      end

    Enum.find(result, &find_track/1)
    |> map_track()
  end

  defp map_track({"tracks", %{"items" => [track | _]}}), do: Map.take(track, ["uri"])
  defp map_track(_rest), do: nil
  defp find_track(%{"tracks" => %{"items" => [%{"type" => "track"}]}}), do: True
  defp find_track(_rest), do: False
end
