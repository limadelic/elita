defmodule FreeqCase do
  defmacro __using__(_opts) do
    quote do
      use Tester
      import String, only: [to_atom: 1]
      import Agent, only: [start_link: 1]

      import FreeqTestClient,
        only: [say: 1, hears: 1, connect: 0, register_brian: 0, wait_join: 1]

      Code.require_file("../support/server.exs", __DIR__)
      Code.require_file("../support/freeq_client.exs", __DIR__)

      setup do
        Server.wait(~c"127.0.0.1", 6667)
        socket = setup_socket()
        on_exit(fn -> :gen_tcp.close(socket) end)
        :ok
      end

      defp setup_socket do
        {:ok, socket} = connect()
        init(socket)
        socket
      end

      defp init(socket) do
        {:ok, counter} = start_link(fn -> 1 end)
        store(socket, counter)
      end

      defp store(socket, counter) do
        Process.put(:freeq_socket, socket)
        Process.put(:freeq_counter, counter)
        register_brian()
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
        wait_join(name)
      end
    end
  end
end
