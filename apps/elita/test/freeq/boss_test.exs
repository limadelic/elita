defmodule FreeqBossTest do
  use Tester

  Code.require_file("../support/server.exs", __DIR__)

  @tag cassette: "boss"
  test "boss delegates in the lab" do
    Server.wait(~c"127.0.0.1", 6667)
    {:ok, socket} = connect()
    {:ok, counter} = Agent.start_link(fn -> 1 end)

    Tester.spawn(:boss)
    Tester.spawn(:dev, :worker)
    Tester.spawn(:qa, :worker)

    register_brian(socket, counter)

    {:ok, boss_pid} = Elita.Freeq.start_link(agent: "boss", channel: "#the-lab", driver: "brian")
    {:ok, dev_pid} = Elita.Freeq.start_link(agent: "dev", channel: "#the-lab", driver: "brian")
    {:ok, qa_pid} = Elita.Freeq.start_link(agent: "qa", channel: "#the-lab", driver: "brian")

    wait_join(socket, "boss", counter)
    wait_join(socket, "dev", counter)
    wait_join(socket, "qa", counter)

    send_turn(
      socket,
      "#the-lab",
      "boss: you manage a software development team with a dev and a qa",
      counter
    )

    wait_fragment(socket, "ready", counter)

    send_turn(socket, "#the-lab", "boss: we need more test created", counter)
    wait_fragment(socket, "done", counter)

    send_turn(socket, "#the-lab", "dev: did you receive a task from boss?", counter)
    wait_fragment(socket, "no", counter)

    send_turn(socket, "#the-lab", "qa: did you receive a task from boss?", counter)
    wait_fragment(socket, "yes", counter)

    :gen_tcp.close(socket)
    GenServer.stop(boss_pid)
    GenServer.stop(dev_pid)
    GenServer.stop(qa_pid)
  end

  defp connect do
    :gen_tcp.connect(~c"127.0.0.1", 6667, [
      :binary,
      {:packet, :line},
      {:active, false},
      {:reuseaddr, true},
      {:nodelay, true}
    ])
  end

  defp register_brian(socket, counter) do
    :gen_tcp.send(socket, "NICK brian\r\n")
    :gen_tcp.send(socket, "USER brian 0 * :brian\r\n")

    deadline = System.monotonic_time(:millisecond) + 5000
    wait_for_line(socket, deadline, fn line -> String.contains?(line, "001") end, counter)

    :gen_tcp.send(socket, "JOIN #the-lab\r\n")
    wait_for_line(socket, deadline, fn line -> String.contains?(line, " 366 ") end, counter)
  end

  defp wait_join(socket, agent, counter) do
    deadline = System.monotonic_time(:millisecond) + 5000

    wait_for_line(
      socket,
      deadline,
      fn line ->
        String.contains?(line, agent) and String.contains?(line, "JOIN")
      end,
      counter
    )
  end

  defp send_turn(socket, channel, text, _counter) do
    :gen_tcp.send(socket, "PRIVMSG #{channel} :#{text}\r\n")
  end

  defp wait_fragment(socket, fragment, counter) do
    deadline = System.monotonic_time(:millisecond) + 5000

    scan_for_fragment(socket, deadline, fragment, counter)
  end

  defp scan_for_fragment(socket, deadline, fragment, counter) do
    remaining = deadline - System.monotonic_time(:millisecond)

    if remaining <= 0 do
      raise "Timeout waiting for fragment: #{fragment}"
    end

    case :gen_tcp.recv(socket, 0, remaining) do
      {:ok, data} ->
        lines = String.split(data, "\r\n", trim: true)
        count_and_print(lines, counter)

        fragment_lower = String.downcase(fragment)

        case Enum.find(lines, fn line ->
               String.contains?(String.downcase(line), fragment_lower)
             end) do
          nil ->
            scan_for_fragment(socket, deadline, fragment, counter)

          _line ->
            :ok
        end

      {:error, :timeout} ->
        raise "Timeout waiting for fragment: #{fragment}"

      {:error, reason} ->
        raise "Socket error: #{inspect(reason)}"
    end
  end

  defp wait_for_line(socket, deadline, matcher, counter) do
    remaining = deadline - System.monotonic_time(:millisecond)

    if remaining <= 0 do
      raise "Timeout waiting for matching line"
    end

    case :gen_tcp.recv(socket, 0, remaining) do
      {:ok, data} ->
        lines = String.split(data, "\r\n", trim: true)
        count_and_print(lines, counter)

        case Enum.find(lines, fn line -> matcher.(line) end) do
          nil ->
            wait_for_line(socket, deadline, matcher, counter)

          _line ->
            :ok
        end

      {:error, :timeout} ->
        raise "Timeout waiting for matching line"

      {:error, reason} ->
        raise "Socket error: #{inspect(reason)}"
    end
  end

  defp count_and_print(lines, counter) do
    lines
    |> Enum.each(fn line ->
      count = Agent.get_and_update(counter, fn c -> {c, c + 1} end)
      IO.puts("#{count}: #{line}")
    end)
  end
end
