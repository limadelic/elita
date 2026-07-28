import Config

config :matrix, :trace, System.get_env("EL_TRACE")

if System.get_env("RELEASE_NAME") do
  config :elita, :join_mesh, true
end
