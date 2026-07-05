defmodule Now do
  import Application, only: [get_env: 3]
  import Kernel

  def time do
    get_env(:elita, :clock, &default/0).()
  end

  defp default do
    DateTime.now!(:local) |> DateTime.to_time()
  end
end
