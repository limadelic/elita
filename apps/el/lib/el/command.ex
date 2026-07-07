defmodule El.Command do
  @moduledoc false

  alias El.Command.Ls
  alias El.Command.Delegator

  defdelegate ls(path), to: Ls, as: :run
  defdelegate ask(agent, msg, tool \\ nil), to: Delegator
  defdelegate tell(agent, msg, tool \\ nil), to: Delegator
  defdelegate spawn(name, agent), to: Delegator
  defdelegate claude(name), to: Delegator
  defdelegate cd(path), to: Delegator
  defdelegate daemon(), to: Delegator
end
