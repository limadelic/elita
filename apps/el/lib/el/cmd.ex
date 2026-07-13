defmodule El.Cmd do
  @moduledoc false
  import System, only: [get_env: 2]
  import String, only: [replace: 3]

  def build do
    base() <> prompt(get_env("EL_SYSTEM_PROMPT", nil))
  end

  defp base do
    "claude --dangerously-skip-permissions --model #{get_env("CLAUDE_MODEL", "haiku")}"
  end

  defp prompt(p) when is_binary(p) do
    clean = replace(replace(p, "\n", " "), "\r", " ")
    " --append-system-prompt '#{clean}'"
  end

  defp prompt(_), do: ""
end
