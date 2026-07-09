defmodule El.Command do
  @moduledoc false

  defdelegate ls(path), to: El.Command.Ls, as: :run
  defdelegate ask(agent, msg, tool \\ nil), to: El.Command.Delegator
  defdelegate tell(agent, msg, tool \\ nil), to: El.Command.Delegator
  defdelegate spawn(name, agent), to: El.Command.Delegator
  defdelegate claude(name), to: El.Command.Delegator
  defdelegate cd(path), to: El.Command.Delegator
  defdelegate daemon(), to: El.Command.Delegator
end
