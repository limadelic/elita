defmodule El.Bin do
  @moduledoc false
  import Application, only: [get_env: 2]
  import System, only: [find_executable: 1]

  def locate, do: pick(get_env(:el, :claude))

  defp pick(env) when is_binary(env), do: env
  defp pick(_), do: fallback(find_executable("claude"))

  defp fallback(nil), do: "claude"
  defp fallback(path), do: path
end
