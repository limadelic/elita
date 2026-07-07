defmodule El.CLI.DaemonConnector do
  @moduledoc "Connects to daemon and executes commands via RPC."
  import :rpc, only: [call: 4]

  def connect_and_rpc(command, args) do
    daemon_node = :"elita@127.0.0.1"
    Node.connect(daemon_node) |> connect(command, args, daemon_node)
  end

  defp connect(true, command, args, node) do
    rpc_call(command, args, node)
  end

  defp connect(false, _command, _args, _node) do
    :local
  end

  defp rpc_call(command, args, node) do
    call(node, El.CLI, :dispatch, [command, args])
  rescue
    _ -> :local
  catch
    _ -> :local
  end
end
