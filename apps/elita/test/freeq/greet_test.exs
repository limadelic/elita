defmodule Freeq.GreetTest do
  use Tester

  @moduletag :freeq

  import Brian

  brian "greet" do
    {agent, sock, pid} = Freeq.spawn(:greet)

    on_exit(fn ->
      part(sock, "#the-lab")
      quit(sock)
      send(pid, :stop)
    end)

    pause()
    wait_join(current_room(), agent, "#the-lab")
  end
end
