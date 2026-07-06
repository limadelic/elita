defmodule El.Commands.Tell do
  @moduledoc false
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
    text = cond do
      String.contains?(msg, "\n") ->
        "\e[200~#{msg}\e[201~\r"
      control_sequence?(msg) ->
        msg
      true ->
        "#{msg}\r"
    end
    GenServer.cast({:claude, target}, {:inject, text})
  end

  defp control_sequence?(msg) do
    case :binary.at(msg, 0) do
      nil -> false
      byte -> byte < 32 or byte == 0x1B
    end
  end

  defp default(agent, msg) do
    {:ok, _pid} = start_link(agent, [agent])
    cast(agent, msg)
  end
end
