defmodule Agent.Ask do
  import String, only: [trim: 1]
  import Tape, only: [handle: 3]
  import Agent.Watch, only: [start: 3]

  def reply(name, message, body, folder, runner) do
    start(name, message, folder)
    process(name, body, message, folder, runner)
  rescue
    _ -> ""
  end

  defp process(name, body, message, folder, runner) do
    response = handle(body, name, fn -> runner.(message, folder) end)
    emit(response, name)
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
  rescue
    _ -> :ok
  end
end
