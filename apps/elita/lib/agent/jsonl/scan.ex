defmodule Agent.Jsonl.Scan do
  import Agent.Jsonl.Locate, only: [find: 1]

  def find(folder) do
    find(folder)
  rescue
    _ -> nil
  end
end
