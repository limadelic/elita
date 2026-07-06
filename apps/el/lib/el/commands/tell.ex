defmodule El.Commands.Tell do
  import Elita, only: [start_link: 2, cast: 2]
  import El.Distribution, only: [start: 0]

  def execute(agent, msg) do
    start()
    target = :"el_#{agent}@127.0.0.1"

    if Node.connect(target) do
      inject(msg, target)
    else
      default(agent, msg)
    end
  end

  defp inject(msg, target) do
    text = if String.contains?(msg, "\n") do
      "\e[200~#{msg}\e[201~\r"
    else
      "#{msg}\r"
    end
    GenServer.cast({:claude, target}, {:inject, text})
  end

  defp default(agent, msg) do
    {:ok, _pid} = start_link(agent, [agent])
    cast(agent, msg)
  end
end
