import Config

tape_handler =
  case System.get_env("TAPE") do
    "rec" -> &Tape.Record.handle/3
    nil ->
      case System.get_env("LIVE") do
        "1" -> fn _body, _agent_name, fun -> fun.() end
        _ -> &Tape.Play.handle/3
      end
    _ -> &Tape.Play.handle/3
  end

config :elita, :tape_handler, tape_handler
