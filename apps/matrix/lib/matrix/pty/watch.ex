defmodule Matrix.Pty.Watch do
  @moduledoc false
  import Task.Supervisor, only: [start_child: 2]

  def start(pty) do
    caller = self()
    start_child(Matrix.Tasks, fn -> probe(caller, pty) end)
  end

  defp probe(parent, pty) when is_port(pty) do
    :erlang.monitor(:port, pty)
    wait(parent, pty)
  end

  defp probe(_parent, _pty) do
    :ok
  end

  defp wait(parent, pty) do
    receive do
      {:DOWN, _ref, :port, ^pty, _reason} -> send(parent, {pty, :closed})
    end
  end
end
