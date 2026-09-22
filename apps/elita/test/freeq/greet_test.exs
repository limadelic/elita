defmodule FreeqGreetTest do
  use Tester

  Code.require_file("../support/server.exs", __DIR__)

  @tag cassette: "greet_lab"
  test "brian and greet have a real conversation in the lab" do
    Server.wait(~c"127.0.0.1", 6667)
    {:ok, socket} = connect()
    {:ok, counter} = Agent.start_link(fn -> 1 end)

    register_brian(socket, counter)

    {:ok, greet_pid} =
      Elita.Freeq.start_link(
        agent: "greet",
        channel: "#the-lab",
        ask: &tape_ask/2
      )

    assert_greet_joins(socket, counter)

    send_turn(socket, "#the-lab", "greet: hello", counter)
    wait_fragment(socket, "who am i talking to", counter)

    Process.sleep(3000)

    send_turn(socket, "#the-lab", "greet: Mike", counter)
    wait_fragment(socket, "wonderful to meet you", counter)

    Process.sleep(3000)

    send_turn(socket, "#the-lab", "greet: how are you?", counter)
    wait_fragment(socket, "i am greeeet", counter)

    :gen_tcp.close(socket)
    GenServer.stop(greet_pid)
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

  defp assert_greet_joins(socket, counter) do
    deadline = System.monotonic_time(:millisecond) + 5000

    wait_for_line(
      socket,
      deadline,
      fn line ->
        String.contains?(line, "greet") and String.contains?(line, "JOIN")
      end,
      counter
    )
  end

  defp send_turn(socket, channel, text, counter) do
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

  defp tape_ask(agent, text) do
    body = %{messages: [%{content: text}]}

    Tape.handle(
      body,
      agent,
      fn -> {:error, :no_tape_response} end,
      tape: System.get_env("TAPE"),
      on_miss: :raise
    )
    |> extract_text()
  end

  defp extract_text([%{"text" => text, "type" => "text"} | _]), do: text
  defp extract_text([%{"text" => text} | _]), do: text
  defp extract_text(error), do: error
end
