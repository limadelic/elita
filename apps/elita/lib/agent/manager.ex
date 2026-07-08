defmodule Agent.Manager do
  import Agent.Config, only: [load: 0]
  import Agent.Session, only: [start_link: 1]
  import Enum, only: [each: 2]
  import Logger, only: [info: 1, error: 1]

  def start_agents do
    load()
    |> each(&boot_agent/1)
  end

  defp boot_agent({name, folder}) do
    start_link(name: name, folder: folder)
    |> handle_boot_result(name, folder)
  end

  defp handle_boot_result({:ok, _pid}, name, folder) do
    info("Agent booted: #{name} at #{folder}")
  end

  defp handle_boot_result({:error, reason}, name, _folder) do
    error("Failed to boot #{name}: #{inspect(reason)}")
  end
end
