defmodule Agent.Manager do
  require Logger
  import Agent.Config, only: [load: 0]
  import Agent.Session, only: [start_link: 1]

  def start_agents do
    load()
    |> Enum.each(&boot_agent/1)
  end

  defp boot_agent({name, folder}) do
    start_link(name: name, folder: folder)
    |> handle_boot_result(name, folder)
  end

  defp handle_boot_result({:ok, _pid}, name, folder) do
    Logger.info("Agent booted: #{name} at #{folder}")
  end

  defp handle_boot_result({:error, reason}, name, _folder) do
    Logger.error("Failed to boot #{name}: #{inspect(reason)}")
  end
end
