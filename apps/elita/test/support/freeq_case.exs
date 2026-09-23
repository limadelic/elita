defmodule FreeqCase do
  defmacro __using__(_opts) do
    quote do
      use Tester

      Code.require_file("../support/server.exs", __DIR__)
      Code.require_file("../support/freeq_client.exs", __DIR__)

      setup do
        Server.wait(~c"127.0.0.1", 6667)
        {:ok, socket} = FreeqTestClient.connect()
        {:ok, counter} = Agent.start_link(fn -> 1 end)

        FreeqTestClient.register_brian(socket, counter)

        on_exit(fn -> :gen_tcp.close(socket) end)

        {:ok, socket: socket, counter: counter}
      end
    end
  end
end
