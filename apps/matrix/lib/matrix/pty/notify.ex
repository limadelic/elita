defmodule Matrix.Pty.Notify do
  @moduledoc false
  import Enum, only: [each: 2]

  def notify(taps, data) do
    each(taps, fn pid ->
      send(pid, {:output, data})
    end)
  end
end
