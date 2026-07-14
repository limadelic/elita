defmodule Agent.Portal do
  import Agent.Session, only: [ask: 2]

  def response(_agent, question) do
    pid = find_puppet()

    case pid do
      :undefined -> "unknown: malko"
      pid -> puppet_ask(pid, question)
    end
  end

  defp find_puppet do
    # Debug: log all global names
    all_names = :global.registered_names()
    File.write!("/tmp/portal_trace.log", "[FIND-PUPPET] all_names=#{inspect(all_names)}\n", [:append])

    case :global.whereis_name({:malko, :puppet}) do
      :undefined ->
        File.write!("/tmp/portal_trace.log", "[FIND-PUPPET] not found, trying alternatives\n", [:append])
        :undefined
      pid ->
        File.write!("/tmp/portal_trace.log", "[FIND-PUPPET] found pid=#{inspect(pid)}\n", [:append])
        pid
    end
  end

  defp puppet_ask(pid, question) do
    {:ok, resp} = ask(pid, question)
    resp
  end
end
