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

      import Registry, only: [lookup: 2]

      setup do
        p = port()
        Server.wait(~c"127.0.0.1", p)
        {:ok, socket} = connect()
        Process.put(:freeq_socket, socket)
        register_brian()
        on_exit(fn -> :gen_tcp.close(socket) end)
        :ok
      end

      def spawn(name, _role) do
        spawn(name)
      end

      def spawn(name) do
        lab = "#the-lab"
        {:ok, _agent_pid, _freeq_pid} = Freeq.Resident.start(
          name, lab, ~c"127.0.0.1", port())
        agent_name = to_string(name)
        on_exit(fn -> stop_freeq_service(agent_name) end)
        wait_join(agent_name)
      end

      defp stop_freeq_service(agent_name) do
        stop_greet_agent(agent_name)
        stop_freeq_bridge(agent_name)
      end

      defp stop_greet_agent(agent_name) do
        lookup(ElitaRegistry, agent_name) |> stop_agent_process()
      end

      defp stop_agent_process([{agent_pid, _meta}]) do
        GenServer.stop(agent_pid)
      end

      defp stop_agent_process([]) do
        :ok
      end

      defp stop_freeq_bridge(agent_name) do
        freeq_process_name = "freeq_#{agent_name}" |> String.to_atom()
        Process.whereis(freeq_process_name) && GenServer.stop(freeq_process_name)
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

      defp port, do: FreeqTestClient.freeq_port()
    end
  end
end
