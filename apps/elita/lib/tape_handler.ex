defmodule TapeHandler do
  def handle(body, name, fun) do
    case System.get_env("TAPE") do
      nil -> fun.()
      _ -> Tape.Play.handle(body, name, fun)
    end
  end
end
