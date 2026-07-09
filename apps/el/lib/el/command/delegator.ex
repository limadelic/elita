defmodule El.Command.Delegator do
  @moduledoc false

  import El.Commands.Spawn, only: [execute: 2]

  def ask(agent, msg, tool \\ nil), do: El.Commands.Ask.ask(agent, msg, tool)
  def tell(agent, msg, tool \\ nil), do: El.Commands.Tell.tell(agent, msg, tool)
  def spawn(name, agent), do: execute(name, agent)
  def claude(name), do: El.Commands.Claude.claude(name)
  def cd(path), do: El.Commands.Cd.cd(path)
  def daemon, do: El.Distribution.daemon()
end
