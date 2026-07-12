defmodule El.Puppet.Record do
  import System, only: [get_env: 1]
  import Tape.Store, only: [add: 2]

  def save(message, response) do
    save(message, response, get_env("TAPE"))
  end

  defp save(_message, _response, nil), do: :ok
  defp save(_message, _response, ""), do: :ok

  defp save(message, response, "rec") do
    request = %{"agent" => name(), "messages" => [%{content: message}], "n" => 1}
    add(request, response)
  end

  defp save(_message, _response, _tape), do: :ok

  defp name do
    name(get_env("PUPPET_NAME"))
  end

  defp name(nil), do: "puppet"
  defp name(n), do: n
end
