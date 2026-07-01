defmodule Tape do
  alias Tape.Store
  alias Tape.Replay

  def play(body, agent_name, request_fun) do
    mode = System.get_env("REC")
    play_mode(mode, body, agent_name, request_fun)
  end

  defp play_mode("1", body, agent_name, request_fun),
    do: Store.record(body, agent_name, request_fun)
  defp play_mode(_mode, body, agent_name, request_fun),
    do: Replay.replay_or_record(body, agent_name, request_fun)
end
