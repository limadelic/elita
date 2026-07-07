defmodule El.Commands.Ask.Remote do
  @moduledoc false
  import :binary, only: [at: 2]
  import String, only: [contains?: 2]

  alias El.Answer

  def ask(msg, target, proc, tool) do
    wrap = fn -> print(msg, target, proc) end
    tap(target, proc, wrap, tool)
  end

  defp print(msg, target, proc) do
    result = answer(msg, target, proc)
    IO.puts(result)
  end

  defp tap(target, proc, fun, _tool) do
    :ok = GenServer.call({proc, target}, {:tap, self()})
    result = fun.()
    :ok = GenServer.call({proc, target}, {:untap, self()})
    result
  end

  defp answer(msg, target, proc) do
    text = format(msg)
    ref = make_ref()
    reply = {ref, self()}
    GenServer.cast({proc, target}, {:inject, text, reply: reply})
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
