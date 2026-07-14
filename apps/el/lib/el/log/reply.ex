defmodule El.Log.Reply do
  import String, only: [trim: 1]
  import Log, only: [write: 1]

  def handle(response, agent) do
    match(response, agent)
  end

  defp match([%{"text" => text} | _], agent) do
    text |> trim() |> build(agent) |> emit()
  end

  defp match(response, _agent) do
    response
  end

  defp build(text, agent) do
    "✨ #{agent} | #{text}\n"
  end

  defp emit(line) do
    write(line)
  end
end
