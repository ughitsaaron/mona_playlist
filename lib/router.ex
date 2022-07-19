defmodule Mona.Router do
  use Plug.Router

  plug(Plug.Session,
    store: :cookie,
    key: "_mona_app",
    signing_salt: "abcd1234"
  )

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Poison
  )

  plug(:match)
  plug(:dispatch)

  plug(Ueberauth)

  get "/" do
    url = "http://localhost:4000/auth/auth0"

    conn
    |> put_resp_header("location", url)
    |> send_resp(conn.status || 302, "redirecting")
  end

  get("/auth/auth0", do: conn)

  get "/auth/auth0/callback" do
    conn
    |> send_resp(conn.status || 302, "yay")
  end

  # get "/run" do
  #   conn
  #   |> send_resp(200, Poison.encode!(%{status: "yay"}))
  # end

  match _ do
    send_resp(conn, 200, "hellloooo")
  end
end
