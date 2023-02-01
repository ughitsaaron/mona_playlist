defmodule Mona.Spotify.Fetch do
  alias HTTPoison
  use HTTPoison.Base

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

  def authorize(conn) do
    body =
      URI.encode_query(%{
        code: conn.params["code"],
        redirect_uri: Application.fetch_env!(:mona, :redirect_uri),
        grant_type: "authorization_code"
      })

    client_id = Application.fetch_env!(:mona, :client_id)
    client_secret = Application.fetch_env!(:mona, :client_secret)
    authorization = Base.encode64(client_id <> ":" <> client_secret)

    headers = [
      {"Authorization", "Basic #{authorization}"},
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    HTTPoison.post!(
      "https://accounts.spotify.com/api/token",
      body,
      headers
    )
    |> Map.get(:body)
  end
end
