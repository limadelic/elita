defmodule El.Pty.Notify do
  @moduledoc false
  import Enum, only: [each: 2]
  import El.Log, only: [write: 1]

  def notify(taps, data) do
    each(taps, fn pid ->
      write("broadcast: sending #{byte_size(data)}b to #{inspect(pid)}\n")
      send(pid, {:output, data})
    end)
  end
end
