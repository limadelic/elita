defmodule Now do
  import Application, only: [get_env: 3]

  def time do
    get_env(:elita, :clock, &default/0).()
  end

  defp default do
    :calendar.local_time()
  end
end
