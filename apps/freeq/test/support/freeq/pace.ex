defmodule Freeq.Pace do
  import Process, only: [sleep: 1]
  import System, only: [get_env: 1]

  def join do
    if get_env("FREEQ_PACE") do
      sleep(1000)
    end
  end

  def bubble(text) do
    if get_env("FREEQ_PACE") do
      time = 4500 + String.length(text) * 30
      sleep(time)
    end
  end
end
