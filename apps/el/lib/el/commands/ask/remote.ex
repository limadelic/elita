defmodule El.Commands.Ask.Remote do
  @moduledoc false
  import :binary, only: [at: 2]
  import String, only: [contains?: 2]

  alias El.Answer

  def remote_ask(msg, target, process_name, tool) do
    wrap = fn -> print_answer(msg, target, process_name) end
    tap(target, process_name, wrap, tool)
  end

  defp print_answer(msg, target, process_name) do
    result = answer(msg, target, process_name)
    IO.puts(result)
  end

  defp tap(target, process_name, fun, _tool) do
    :ok = GenServer.call({process_name, target}, {:tap, self()})
    result = fun.()
    :ok = GenServer.call({process_name, target}, {:untap, self()})
    result
  end

  defp answer(msg, target, process_name) do
    text = format(msg)
    ref = make_ref()
    reply_to = {ref, self()}
    GenServer.cast({process_name, target}, {:inject, text, reply_to: reply_to})
    Answer.await(ref, 30_000)
  end

  defp format(msg), do: formatted(contains?(msg, "\n"), msg)

  defp formatted(true, msg), do: "\e[200~#{msg}\e[201~\r"

  defp formatted(false, msg) do
    b = at(msg, 0)
    return(special?(b), msg)
  end

  defp return(true, msg), do: msg
  defp return(false, msg), do: "#{msg}\r"

  defp special?(nil), do: false
  defp special?(0x1B), do: true
  defp special?(b) when b < 32, do: true
  defp special?(_), do: false
end
