defmodule TapeHandler do
  def handle(body, name, fun) do
    handle_mode(body, name, fun, System.get_env("TAPE"))
  end

  defp handle_mode(_body, _name, fun, nil), do: fun.()
  defp handle_mode(body, name, fun, _), do: TapeWrapper.safe_handle(body, name, fun)
end
