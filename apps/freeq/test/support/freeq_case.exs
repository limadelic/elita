defmodule FreeqCase do
  Code.require_file("../../../elita/test/support/tester.exs", __DIR__)
  Code.require_file("freeq_client.exs", __DIR__)

  defmacro __using__(_opts) do
    quote do
      use Tester, except: [spawn: 1, spawn: 2, ask: 2, tell: 2]

      Code.require_file("../support/server.exs", __DIR__)

      import FreeqTestClient,
        only: [say: 1, hears: 1, connect: 0, register_brian: 0, wait_join: 1, reply: 1]

      import Freeq.Pace, only: [join: 0, bubble: 1]

      setup do
        p = port()
        Server.wait(~c"127.0.0.1", p)
        {:ok, socket} = connect()
        Process.put(:freeq_socket, socket)
        register_brian()
        on_exit(fn -> :gen_tcp.close(socket) end)
        :ok
      end

      def spawn(name) do
        {:ok, agent_pid, freeq_pid} = Freeq.Resident.start(name, "#the-lab", ~c"127.0.0.1", port(), "brian")
        on_exit(fn -> GenServer.stop(agent_pid) end)
        on_exit(fn -> GenServer.stop(freeq_pid) end)
        wait_join(to_string(name))
      end

      def spawn(name, role) do
        {:ok, agent_pid, freeq_pid} = Freeq.Resident.start(name, "#the-lab", ~c"127.0.0.1", port(), "brian")
        on_exit(fn -> GenServer.stop(agent_pid) end)
        on_exit(fn -> GenServer.stop(freeq_pid) end)
        wait_join(to_string(name))
      end

      def ask(agent, query) do
        say("@#{agent} #{query}")
        answer = reply(agent)
        bubble(answer)
        answer
      end

      def tell(agent, msg) do
        say("#{agent}: #{msg}")
        reply(agent)
        :ok
      end

      def join(agent, role \\ nil), do: boot(agent, role)

      defp boot(name, nil), do: __MODULE__.spawn(name)
      defp boot(name, role), do: __MODULE__.spawn(name, role)

      defp port do
        String.to_integer(System.get_env("FREEQ_PORT", "6667"))
      end
    end
  end
end
