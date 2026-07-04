defmodule TapeWrapper do
  def safe_handle(body, name, fun) do
    try do
      Tape.Play.handle(body, name, fun)
    catch
      class, reason -> on_catch(class, reason, fun)
    end
  end

  defp on_catch(:error, _e, fun), do: fun.()
  defp on_catch(:exit, reason, fun), do: on_exit(reason, fun)

  defp on_exit(reason, fun) do
    on_exit(reason, fun, String.contains?(inspect(reason), "no process"))
  end

  defp on_exit(_reason, fun, true), do: fun.()
  defp on_exit(reason, _fun, false), do: exit(reason)
end
