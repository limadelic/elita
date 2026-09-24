defmodule Freeq.GreetTest do
  use Tester

  @moduletag :freeq

  import Brian

  brian "greet" do
    {agent, sock, pid} = Freeq.spawn(:greet)

    on_exit(fn ->
      part(sock, "#the-lab", agent)
      quit(sock)
      send(pid, :stop)
    end)

    pause()
    watch(room, agent, "#the-lab")
  end
end
