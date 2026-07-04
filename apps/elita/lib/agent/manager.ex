defmodule Agent.Manager do
  require Logger

  def start_agents do
    Agent.Config.load()
    |> Enum.each(&boot_agent/1)
  end

  defp boot_agent({name, folder}) do
    Agent.Session.start_link(name: name, folder: folder)
    |> handle_boot_result(name, folder)
  end

  defp handle_boot_result({:ok, pid}, name, folder) do
    Agent.Registry.register(name, folder, pid)
    Logger.info("Agent booted: #{name} at #{folder}")
  end

  defp handle_boot_result({:error, reason}, name, _folder) do
    Logger.error("Failed to boot #{name}: #{inspect(reason)}")
  end
end
