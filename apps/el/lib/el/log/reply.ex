defmodule El.Log.Reply do
  import String, only: [trim: 1]
  import Log, only: [answer: 2]

  def handle(response, agent) do
    match(response, agent)
  end

  defp match([%{"text" => text} | _], agent) do
    text |> trim() |> emit(agent)
  end

  defp match(response, _agent) do
    response
  end

  defp emit(text, agent) do
    answer(agent, text)
  end
end
