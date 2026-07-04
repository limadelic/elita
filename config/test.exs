import Config

if System.get_env("TAPE") do
  config :elita, tape_handler: &Tape.Play.handle/3
end
