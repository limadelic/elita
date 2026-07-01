import Config

tape_handler =
  case System.get_env("TAPE") do
    "rec" -> &Tape.Record.handle/3
    _ -> &Tape.Play.handle/3
  end

config :elita, :tape_handler, tape_handler
