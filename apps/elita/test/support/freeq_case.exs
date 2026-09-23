defmodule FreeqCase do
  Code.require_file("../support/freeq_client.exs", __DIR__)

  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case
      import Kernel, except: [spawn: 1, spawn: 2]
      import Tester, except: [spawn: 1, spawn: 2, ask: 2]
      import String, only: [to_atom: 1]

      Code.require_file("../support/server.exs", __DIR__)

      import FreeqTestClient,
        only: [say: 1, hears: 1, connect: 0, register_brian: 0, wait_join: 1]

      setup_all do
        case Tape.Writer.start_link(nil) do
          {:ok, _} -> :ok
          {:error, {:already_started, _}} -> :ok
        end

        System.put_env("CASSETTE_DIR", Path.expand("../../../../features/cassettes", __DIR__))

        :ok
      end

      setup context do
        cassette = context[:cassette] || default_cassette()
        System.put_env("CASSETTE", cassette)
        Tape.Writer.reset()

        Server.wait(~c"127.0.0.1", 6667)
        {:ok, socket} = connect()
        Process.put(:freeq_socket, socket)
        register_brian()
        on_exit(fn -> :gen_tcp.close(socket) end)
        :ok
      end

      defp default_cassette do
        __MODULE__
        |> Module.split()
        |> List.last()
        |> String.replace_suffix("Test", "")
        |> String.downcase()
      end

      def spawn(name) do
        Tester.spawn(name)
        run(name)
      end

      def spawn(name, role) do
        Tester.spawn(name, role)
        run(name)
      end

      def ask(agent, query) do
        name = to_string(agent)
        say("#{name}: #{query}")
        gather_response(name, [], 0)
      end

      defp gather_response(_agent, acc, 10) do
        Enum.reverse(acc) |> Enum.join("\n") |> String.trim()
      end

      defp gather_response(agent, acc, count) do
        try do
          line = get_agent_response(agent)
          msg = extract_message(line)
          new_acc = [msg | acc]

          if String.trim(msg) == "" or String.match?(msg, ~r/[.!?]\s*$/) do
            Enum.reverse(new_acc) |> Enum.join("\n") |> String.trim()
          else
            gather_response(agent, new_acc, count + 1)
          end
        rescue
          _ -> Enum.reverse(acc) |> Enum.join("\n") |> String.trim()
        end
      end

      defp get_agent_response(agent) do
        line = hears(agent)

        if String.starts_with?(line, ":#{agent}!") do
          line
        else
          get_agent_response(agent)
        end
      end

      def tell(agent, msg) do
        name = to_string(agent)
        say("#{name}: #{msg}")
        hears(name)
      end

      def join(agent, role \\ nil) do
        boot(agent, role)
        run(agent)
      end

      defp extract_message(line) do
        case String.split(line, " :", parts: 2) do
          [_prefix, msg] -> msg
          _ -> ""
        end
      end

      defp boot(name, nil), do: Tester.spawn(name)
      defp boot(name, role), do: Tester.spawn(name, role)

      defp run(agent) do
        name = to_string(agent)
        id = to_atom("freeq_#{name}")
        config = [agent: name, channel: "#the-lab", driver: "brian"]
        start_supervised!({Freeq, config}, id: id)
        wait_join(name)
      end
    end
  end
end
