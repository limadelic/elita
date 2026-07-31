defmodule El.Boot.Bind do
  import System, only: [cmd: 2]
  import Node, only: [start: 2]
  import El.Signal, only: [activate: 0]

  def engage(addr) do
    cmd("epmd", ["-daemon"])
    start(addr, :longnames)
    activate()
  end
end
