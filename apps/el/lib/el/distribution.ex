defmodule El.Distribution do
  def start do
    case Node.start(:"el_claude@127.0.0.1", :longnames) do
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
end
