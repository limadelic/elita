defmodule El.Cmd do
  @moduledoc false
  import System, only: [get_env: 2]

  def build do
    base() <> prompt(get_env("EL_SYSTEM_PROMPT", nil))
  end

  defp base do
    "claude --dangerously-skip-permissions --model #{get_env("CLAUDE_MODEL", "haiku")}"
  end

  defp prompt(p) when is_binary(p), do: " --append-system-prompt '#{p}'"
  defp prompt(_), do: ""
end
