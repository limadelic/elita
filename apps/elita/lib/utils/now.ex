defmodule Now do
  import Application, only: [get_env: 3]
  import :calendar, only: [local_time: 0]

  def time do
    get_env(:elita, :clock, &default/0).()
  end

  defp default do
    local_time()
  end
end
