defmodule FreeqCase do
  defmacro __using__(_opts) do
    quote do
      use Tester
      import String, only: [to_atom: 1]

      Code.require_file("../support/server.exs", __DIR__)
      Code.require_file("../support/freeq_client.exs", __DIR__)

      setup do
        Server.wait(~c"127.0.0.1", 6667)
        socket = setup_socket()
        on_exit(fn -> :gen_tcp.close(socket) end)
        :ok
      end

      defp setup_socket do
        {:ok, socket} = FreeqTestClient.connect()
        {:ok, counter} = Agent.start_link(fn -> 1 end)
        Process.put(:freeq_socket, socket)
        Process.put(:freeq_counter, counter)
        FreeqTestClient.register_brian()
        socket
      end

      def join(agent, role \\ nil) do
        boot(agent, role)
        run(agent)
      end

      defp boot(name, nil), do: Tester.spawn(name)
      defp boot(name, role), do: Tester.spawn(name, role)

      defp run(agent) do
        name = to_string(agent)
        id = to_atom("freeq_#{name}")
        config = [agent: name, channel: "#the-lab", driver: "brian"]
        start_supervised!({Elita.Freeq, config}, id: id)
        FreeqTestClient.wait_join(name)
      end
    end
  end
end
