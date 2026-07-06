defmodule El.Distribution do
  def start(name \\ :default) do
    session_name = resolve_session_name(name)
    node_name = :"claude_#{session_name}@127.0.0.1"

    case Node.start(node_name, :longnames) do
      {:ok, _pid} ->
        Node.set_cookie(:elita)
        :ok

      {:error, {:already_started, _pid}} ->
        Node.set_cookie(:elita)
        :ok

      {:error, reason} ->
        IO.write(:stderr, "Warning: Failed to start distribution: #{inspect(reason)}\n")
        :ok
    end
  end

  defp resolve_session_name(:default) do
    File.cwd!()
    |> Path.basename()
  end

  defp resolve_session_name(name) when is_binary(name) do
    name
  end
end
