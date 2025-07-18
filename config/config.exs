import Config

config :api, Api.Endpoint,
  http: [port: 4000],
  server: true,
  adapter: Bandit.PhoenixAdapter

config :phoenix, :json_library, Jason