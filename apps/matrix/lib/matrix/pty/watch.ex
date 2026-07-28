defmodule Matrix.Pty.Watch do
  @moduledoc false
  import Process, except: [alias: 1, info: 1]
  import Port, only: [info: 1]
  import Task.Supervisor, only: [start_child: 2]

  def start(pty) do
    start_child(Matrix.Tasks, fn -> probe(self(), pty) end)
  end

  defp probe(parent, pty) do
    sleep(500)
    react(info(pty), parent, pty)
  end

  defp react(nil, parent, pty), do: send(parent, {pty, :closed})
  defp react(_, _, _), do: :ok
end
