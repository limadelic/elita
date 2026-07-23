defmodule El.Bin do
  @moduledoc false
  import System, only: [get_env: 1, find_executable: 1]

  def locate, do: pick(get_env("CLAUDE"))
  defp pick(env) when is_binary(env), do: env
  defp pick(_), do: find_executable("claude")
end
