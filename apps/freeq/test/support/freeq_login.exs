defmodule FreeqTestLogin do
  def login(socket) do
    :inet.setopts(socket, active: true)
    :ok = Freeq.SASL.login(socket, "brian")
    :ok = Freeq.Welcome.greet(socket, "brian")
    :inet.setopts(socket, active: false)
  end
end
