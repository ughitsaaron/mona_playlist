import Config

config :mona,
  env: config_env(),
  spotify: [
    client_id: System.get_env("SPOTIFY_CLIENT_ID"),
    client_secret: System.get_env("SPOTIFY_CLIENT_SECRET")
  ]
