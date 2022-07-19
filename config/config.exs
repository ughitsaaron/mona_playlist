import Config

config :mona, env: config_env()

config :ueberauth, Ueberauth,
  json_library: Poison,
  providers: [
    auth0: {Ueberauth.Strategy.Auth0, []}
  ]

import_config("dev.exs")
import_config("runtime.exs")
