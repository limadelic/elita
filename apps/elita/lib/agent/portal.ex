defmodule Agent.Portal do
  import String, only: [to_atom: 1, downcase: 1]
  import Agent.Session, only: [ask: 2]

  def response(agent, question) do
    norm = to_atom(agent) |> Kernel.to_string() |> downcase() |> to_atom()

    case :global.whereis_name({norm, :puppet}) do
      :undefined -> "unknown: #{agent}"
      pid -> puppet_ask(pid, question)
    end
  end

  defp puppet_ask(pid, question) do
    {:ok, resp} = ask(pid, question)
    resp
  end
end
