defmodule El.CLI.DaemonConnector do
  @moduledoc "Connects to daemon and executes commands via RPC."
  import :rpc, only: [call: 4]

  def connect_and_rpc(command, args) do
    daemon_node = :"elita@127.0.0.1"
    result = Node.connect(daemon_node)
    handle_connect(result, command, args, daemon_node)
  end

  defp handle_connect(true, command, args, node) do
    rpc_call(command, args, node)
  end

  defp handle_connect(:ok, command, args, node) do
    rpc_call(command, args, node)
  end

  defp handle_connect(:ignored, command, args, node) do
    rpc_call(command, args, node)
  end

  defp handle_connect(false, command, args, node) do
    should_spawn?() |> handle_spawn(command, args, node)
  end

  defp handle_connect(:error, command, args, node) do
    should_spawn?() |> handle_spawn(command, args, node)
  end

  defp handle_spawn(true, command, args, node) do
    spawn_daemon()
    retry_loop(command, args, node, 10)
  end

  defp handle_spawn(false, _command, _args, _node) do
    :local
  end

  defp should_spawn? do
    System.get_env("EL_DAEMON_SPAWN", "true") == "true"
  end

  defp spawn_daemon do
    System.cmd("sh", ["-c", "el daemon &"], stderr_to_stdout: true)
  end

  defp retry_loop(command, args, node, retries) when retries > 0 do
    Process.sleep(500)
    result = Node.connect(node)
    handle_retry(result, command, args, node, retries)
  end

  defp retry_loop(_command, _args, _node, _retries) do
    :local
  end

  defp handle_retry(true, command, args, node, _retries) do
    rpc_call(command, args, node)
  end

  defp handle_retry(:ok, command, args, node, _retries) do
    rpc_call(command, args, node)
  end

  defp handle_retry(:ignored, command, args, node, _retries) do
    rpc_call(command, args, node)
  end

  defp handle_retry(false, command, args, node, retries) do
    retry_loop(command, args, node, retries - 1)
  end

  defp handle_retry(:error, command, args, node, retries) do
    retry_loop(command, args, node, retries - 1)
  end

  defp rpc_call(command, args, node) do
    call(node, El.CLI, :dispatch, [command, args])
  rescue
    _ -> :local
  catch
    _ -> :local
  end
end
