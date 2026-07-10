defmodule Agent.Manager do
  import Agent.Config, only: [load: 0]
  import Agent.Session, only: [start_link: 1]
  import Enum, only: [each: 2]
  import Logger, only: [info: 1, error: 1]

  def launch do
    load()
    |> each(&build/1)
  end

  defp build({name, folder}) do
    start_link(name: name, folder: folder)
    |> report(name, folder)
  end

  defp report({:ok, _pid}, name, folder) do
    info("Agent booted: #{name} at #{folder}")
  end

  defp report({:error, reason}, name, _folder) do
    error("Failed to boot #{name}: #{inspect(reason)}")
  end
end
