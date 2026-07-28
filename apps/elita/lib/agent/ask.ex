defmodule Agent.Ask do
  import String, only: [trim: 1]
  import Tape, only: [handle: 4]
  import Agent.Watch, only: [start: 3]

  def reply(message, body, state) do
    process(message, body, state)
  end

  defp process(message, body, %{name: n, tape: t, live: l, runner: r, folder: f}) do
    start(n, message, f)
    opts = [tape: t, live: l]
    emit(handle(body, n, fn -> r.(message, f) end, opts), n)
  end

  defp emit([%{"text" => text, "type" => "text"}], name) do
    text = trim(text)
    answer(name, text)
    text
  end

  defp emit([%{"text" => text}], name) do
    text = trim(text)
    answer(name, text)
    text
  end

  defp emit(_, _), do: ""

  defp answer(agent, text) do
    :erlang.apply(:"Elixir.Tools.Sys.Ask", :answer, [agent, text])
  end
end
