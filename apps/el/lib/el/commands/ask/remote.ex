defmodule El.Commands.Ask.Remote do
  @moduledoc false
  import :binary, only: [at: 2]
  import String, only: [contains?: 2]
  import IO, only: [puts: 1]
  import GenServer, only: [call: 2, cast: 2]
  import El.Answer, only: [await: 2]

  def relay(msg, target, proc, tool) do
    wrap = fn -> print(msg, target, proc) end
    tap(target, proc, wrap, tool)
  end

  defp print(msg, target, proc) do
    result = answer(msg, target, proc)
    puts(result)
  end

  defp tap(target, proc, fun, _tool) do
    :ok = call({proc, target}, {:tap, self()})
    result = fun.()
    :ok = call({proc, target}, {:untap, self()})
    result
  end

  defp answer(msg, target, proc) do
    {ref, text} = prepare(msg)
    cast({proc, target}, {:inject, text, reply: {ref, self()}})
    await(ref, 30_000)
  end

  defp prepare(msg) do
    text = format(msg)
    ref = make_ref()
    {ref, text}
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
