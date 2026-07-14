defmodule El.Ask do
  import IO, only: [puts: 1]
  import Tools
  import Elita, only: [spawn: 2]

  def invoke(agent, msg) do
    register()
    {parts, _} = exec({[spec(agent, msg)], %{name: "el"}})
    print(parts)
  end

  defp spec(agent, msg) do
    %{"id" => "1", "name" => "ask",
      "input" => %{"recipient" => agent, "question" => msg}}
  end

  defp print([%{"result" => result} | _]), do: puts(result)
  defp print(_), do: :ok

  defp register do
    spawn("el", []) rescue _ -> :ok
  end
end
