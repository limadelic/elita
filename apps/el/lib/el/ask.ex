defmodule El.Ask do
  import IO, only: [puts: 1]
  import Tools
  import Node, only: [start: 2, set_cookie: 1]
  import Application, only: [ensure_all_started: 1]

  def invoke(agent, msg) do
    prime()
    {parts, _} = exec({[spec(agent, msg)], %{name: "el"}})
    print(parts)
  end

  defp spec(agent, msg) do
    %{"id" => "1", "name" => "ask",
      "input" => %{"recipient" => agent, "question" => msg}}
  end

  defp print([%{"result" => result} | _]), do: puts(result)
  defp print(_), do: :ok

  defp prime do
    :os.cmd(~c"epmd -daemon")
    Node.self() |> boot()
    set_cookie(:elita)
    ensure_all_started(:elita)
  end

  defp boot(:nonode@nohost) do
    start(:"ask_#{:erlang.system_time(:millisecond)}@127.0.0.1", :longnames)
  end

  defp boot(_), do: :ok
end
