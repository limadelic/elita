defmodule El.Command.Delegator do
  @moduledoc false

  alias El.Commands.Ask
  alias El.Commands.Cd
  alias El.Commands.Claude
  alias El.Commands.Tell
  alias El.Distribution
  import El.Commands.Spawn, only: [execute: 2]
  import Ask, only: [execute: 3]
  import Tell, only: [execute: 3]
  import Claude, only: [execute: 1]
  import Cd, only: [execute: 1]
  import Distribution, only: [daemon: 0]

  def ask(agent, msg, tool \\ nil), do: Ask.execute(agent, msg, tool)
  def tell(agent, msg, tool \\ nil), do: Tell.execute(agent, msg, tool)
  def spawn(name, agent), do: execute(name, agent)
  def claude(name), do: Claude.execute(name)
  def cd(path), do: Cd.execute(path)
  def daemon, do: Distribution.daemon()
end
