defmodule El.CLI.DaemonConnector do
  @moduledoc "Connects to daemon and executes commands via RPC."

  def connect_and_rpc(command, args) do
    daemon_node = :"elita@127.0.0.1"
    case Node.connect(daemon_node) do
      true -> rpc_call(command, args, daemon_node)
      false -> :local
    end
  end

  defp rpc_call(command, args, node) do
    try do
      :rpc.call(node, El.CLI, :dispatch, [command, args])
    catch
      _ -> :local
    end
  end
end
