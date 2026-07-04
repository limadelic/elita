defmodule Agent.Manager do
  require Logger

  def start_agents do
    Agent.Config.load()
    |> Enum.each(&boot_agent/1)
  end

  defp boot_agent({name, folder}) do
    case Agent.Session.start_link(name: name, folder: folder) do
      {:ok, pid} ->
        Agent.Registry.register(name, folder, pid)
        Logger.info("Agent booted: #{name} at #{folder}")

      {:error, reason} ->
        Logger.error("Failed to boot #{name}: #{inspect(reason)}")
    end
  end
end
