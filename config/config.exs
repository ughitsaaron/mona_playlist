import Config

config :mona,
  env: config_env(),
  spotify: [
    client_id: "d5e3977ccb2a4f919c90b91932116a72",
    client_secret: "01a31e1f4f5c42a5ae9ede257b240bdf",
    scopes: ["user-read-private", "user-read-email", "playlist-modify-private"]
  ]
