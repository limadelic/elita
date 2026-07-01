import Config

tape_handler =
  case System.get_env("TAPE") do
    "rec" -> Tape.Record
    _ -> &Tape.play/3
  end

config :elita, :tape_handler, tape_handler
