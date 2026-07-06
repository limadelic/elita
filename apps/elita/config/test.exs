import Config

tape_handler =
  case {System.get_env("TAPE"), System.get_env("LIVE")} do
    {"rec", _} -> &Tape.Record.handle/3
    {_, "1"} -> fn _body, _agent_name, fun -> fun.() end
    {_, _} -> &Tape.Play.handle/3
  end

clock_fn =
  case {System.get_env("TAPE"), System.get_env("LIVE")} do
    {"rec", _} -> nil
    {_, "1"} -> nil
    {_, _} -> fn -> {{2025, 7, 7}, {10, 0, 0}} end
  end

config :elita, :tape_handler, tape_handler

if clock_fn do
  config :elita, :clock, clock_fn
end
