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

        Process.put(:freeq_socket, socket)
        Process.put(:freeq_counter, counter)

        FreeqTestClient.register_brian()

        on_exit(fn -> :gen_tcp.close(socket) end)

        :ok
      end

      def join(agent, role \\ nil) do
        spawn_agent(agent, role)
        pid = start_freeq(to_string(agent))
        FreeqTestClient.wait_join(to_string(agent))
        cleanup_on_exit(pid)
      end

      defp spawn_agent(name, nil), do: Tester.spawn(name)
      defp spawn_agent(name, role), do: Tester.spawn(name, role)

      defp start_freeq(name) do
        {:ok, pid} = Elita.Freeq.start_link(agent: name, channel: "#the-lab", driver: "brian")
        pid
      end

      defp cleanup_on_exit(pid) do
        on_exit(fn ->
          try do
            GenServer.stop(pid)
          catch
            :exit, _ -> :ok
          end
        end)
      end
    end
  end
end
