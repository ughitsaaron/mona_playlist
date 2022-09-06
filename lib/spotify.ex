defmodule Mona.Spotify do
  use Agent

  def start_link() do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def update(key, value) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))
  end

  def get(key) do
    Agent.get(__MODULE__, &Map.get(&1, key))
  end

  def authorize(conn) do
    url = "https://accounts.spotify.com/api/token"

    body =
      URI.encode_query(%{
        code: conn.params["code"],
        redirect_uri: "http://localhost:4000/auth/callback",
        grant_type: "authorization_code"
      })

    authorization =
      Base.encode64(
        # What is this again? Let's put it in an env file or something
        "d5e3977ccb2a4f919c90b91932116a72" <> ":" <> "01a31e1f4f5c42a5ae9ede257b240bdf"
      )

    headers = [
      {"Authorization", "Basic #{authorization}"},
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    access_token =
      case HTTPoison.post!(url, body, headers) do
        %HTTPoison.Response{status_code: 200, body: body} -> Poison.decode!(body)["access_token"]
      end

    user =
      case HTTPoison.get!("https://api.spotify.com/v1/me", [
             {"Authorization", "Bearer #{access_token}"}
           ]) do
        %HTTPoison.Response{status_code: 200, body: body} -> Poison.decode!(body)
      end

    update(:access_token, access_token)
    update(:user_id, user["id"])
  end

  defp authorization_headers do
    access_token = get(:access_token)

    [
      {"Authorization", "Bearer #{access_token}"}
    ]
  end

  def create_playlist(tracks, title) do
    user_id = get(:user_id)
    url = "https://api.spotify.com/v1/users/#{user_id}/playlists"
    headers = authorization_headers()
    body = Poison.encode!(%{name: title})

    playlist_id =
      case HTTPoison.post!(url, body, headers) do
        %HTTPoison.Response{status_code: 201, body: body} -> Poison.decode!(body)["id"]
      end

    url = "https://api.spotify.com/v1/playlists/#{playlist_id}/tracks"
    body = Poison.encode!(%{uris: Enum.flat_map(tracks, &Map.values/1)})

    case HTTPoison.post!(url, body, headers) do
      %HTTPoison.Response{status_code: 201} -> :ok
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
        %HTTPoison.Response{status_code: 200, body: body} -> Poison.decode!(body)
      end

    Enum.find(result, &find_track/1)
    |> map_track()
  end

  defp map_track({"tracks", %{"items" => [track | _]}}), do: Map.take(track, ["uri"])
  defp map_track(_rest), do: nil
  defp find_track(%{"tracks" => %{"items" => [%{"type" => "track"}]}}), do: True
  defp find_track(_rest), do: False
end
