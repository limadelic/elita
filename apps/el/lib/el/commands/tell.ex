defmodule El.Commands.Tell do
  @moduledoc false
  import Elita, only: [start_link: 2, cast: 2]
  alias El.Distribution

  def execute(agent, msg) do
    Distribution.start()
    claude_target = :"claude_#{agent}@127.0.0.1"
    process_name = String.to_atom(agent)

    if Node.connect(claude_target) do
      inject(msg, claude_target, process_name)
    else
      default(agent, msg)
    end
  end

  defp inject(msg, target, process_name) do
    text = cond do
      String.contains?(msg, "\n") ->
        "\e[200~#{msg}\e[201~\r"
      control_sequence?(msg) ->
        msg
      true ->
        "#{msg}\r"
    end
    GenServer.cast({process_name, target}, {:inject, text})
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
