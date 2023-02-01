import Config

config :mona,
  env: config_env(),
  client_id: System.get_env("SPOTIFY_CLIENT_ID"),
  client_secret: System.get_env("SPOTIFY_CLIENT_SECRET"),
  base_url: System.get_env("REDIRECT_URI", "http://localhost:4000"),
  redirect_uri: System.get_env("REDIRECT_URI", "http://localhost:4000/auth/callback")
