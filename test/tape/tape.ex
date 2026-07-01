defmodule Tape do
  import System, only: [get_env: 1]
  alias Tape.Store
  alias Tape.Replay

  def play(body, agent_name, request_fun) do
    if get_env("REC") == "1", do: Store.record(body, agent_name, request_fun), else: Replay.replay_or_record(body, agent_name, request_fun)
  end
end
