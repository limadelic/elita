defmodule TapeHandler do
  def handle(body, name, fun) do
    case System.get_env("TAPE") do
      nil ->
        fun.()

      _ ->
        try do
          # Try to use tape if Tape.Writer is available
          Tape.Play.handle(body, name, fun)
        rescue
          e ->
            # If tape system fails (e.g., Tape.Writer not started), fall through to real call
            if String.contains?(Exception.message(e), "no process") do
              fun.()
            else
              reraise(e, __STACKTRACE__)
            end
        end
    end
  end
end
