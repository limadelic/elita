defmodule TapeHandler do
  def handle(body, name, fun) do
    case System.get_env("TAPE") do
      nil ->
        fun.()

      _ ->
        try do
          Tape.Play.handle(body, name, fun)
        catch
          :exit, reason ->
            # If tape system exits, fall back to calling fun if it's a known issue
            reason_str = inspect(reason)

            if String.contains?(reason_str, "no process") do
              fun.()
            else
              exit(reason)
            end
        rescue
          _e ->
            # If tape system fails for any reason, fall through to real call
            fun.()
        end
    end
  end
end
