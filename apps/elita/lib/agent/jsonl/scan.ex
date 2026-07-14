defmodule Agent.Jsonl.Scan do
  import Agent.Jsonl.Locate, only: [find: 1]

  def find do
    find(nil)
  rescue
    _ -> nil
  end
end
