import Config

config :logger,
  level: :info,
  format: "[$level] $message\n"

if Mix.env() == :test do
  import_config "test.exs"
end
