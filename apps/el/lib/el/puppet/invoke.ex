defmodule El.Puppet.Invoke do
  import Matrix.Log, only: [write: 1]
  import Tape.Store, only: [add: 2]
  import El.Puppet.Query, only: [call: 2]
  import String, only: [slice: 2]
  import System, only: [get_env: 1]

  def invoke(pty, message) do
    wrap(fn -> attempt(pty, message) end)
  end

  defp wrap(fun) do
    fun.()
  rescue
    e -> trap(e)
  end

  defp trap(reason) do
    error("exception", reason)
  end

  defp attempt(pty, message) do
    respond(pty, message)
  end

  defp respond(pty, message) do
    response = format(call(pty, message))
    log(response)
    record(message, response)
    response
  end

  defp log(response) do
    write("ask returned: #{inspect(slice(inspect(response), 0..50))}\n")
  end

  defp error(kind, reason) do
    write("handle_call #{kind}: #{inspect(reason)}\n")
    {:error, reason}
  end

  defp format(response), do: response

  defp record(message, response) do
    store(message, response, recording?())
  end

  defp store(message, response, true), do: save(message, response)
  defp store(_message, _response, false), do: :ok

  defp recording? do
    get_env("TAPE") == "rec"
  end

  defp save(message, response) do
    persist(build(message), response)
  end

  defp persist(request, response) do
    add(request, response)
  catch
    _, _ -> fail()
  end

  defp build(message) do
    %{"agent" => agent(), "messages" => [%{content: message}], "n" => 1}
  end

  defp agent do
    pick(get_env("PUPPET_NAME"))
  end

  defp pick(nil), do: "puppet"
  defp pick(name), do: name

  defp fail do
    write("record fail\n")
  end
end
