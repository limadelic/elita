defmodule Matrix.Movie.Record do
  @moduledoc false
  import System, only: [get_env: 1]

  def active? do
    get_env("TAPE") == "rec"
  end

  def start(_pty_pid, _name) do
    {:ok, acc_pid} = Agent.start_link(fn -> %{chunks: [], index: 0} end)
    acc_pid
  end

  def record(acc_pid, data) when is_pid(acc_pid) do
    Agent.update(acc_pid, &append(data, &1))
  end

  def get(acc_pid) when is_pid(acc_pid) do
    Agent.get(acc_pid, & &1)
  end

  def done(acc_pid) when is_pid(acc_pid) do
    Agent.stop(acc_pid)
  end

  defp append(data, state) do
    chunk = %{i: state.index, chunk: data}
    %{state | chunks: state.chunks ++ [chunk], index: state.index + 1}
  end
end
