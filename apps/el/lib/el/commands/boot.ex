defmodule El.Commands.Boot do
  import El.Distribution, only: [start: 1]

  def activate(name), do: start(name)
end
