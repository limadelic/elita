defmodule El.Sessions do
  import Agent.Log, only: [reply: 1]

  def log(agent), do: reply(agent)
end
