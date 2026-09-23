defmodule FreeqTestClient do
  def connect do
    :gen_tcp.connect(~c"127.0.0.1", 6667, [
      :binary,
      {:packet, :line},
      {:active, false},
      {:reuseaddr, true},
      {:nodelay, true}
    ])
  end

  def register_brian(socket, counter) do
    :gen_tcp.send(socket, "NICK brian\r\n")
    :gen_tcp.send(socket, "USER brian 0 * :brian\r\n")

    deadline = System.monotonic_time(:millisecond) + 5000
    wait_for_line(socket, deadline, fn line -> String.contains?(line, "001") end, counter)

    :gen_tcp.send(socket, "JOIN #the-lab\r\n")
    wait_for_line(socket, deadline, fn line -> String.contains?(line, " 366 ") end, counter)
  end

  def wait_join(socket, agent, counter) do
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

  def send_turn(socket, channel, text, _counter) do
    :gen_tcp.send(socket, "PRIVMSG #{channel} :#{text}\r\n")
  end

  def wait_fragment(socket, fragment, counter) do
    deadline = System.monotonic_time(:millisecond) + 5000

    scan_for_fragment(socket, deadline, fragment, counter)
  end

  def scan_for_fragment(socket, deadline, fragment, counter) do
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

  def wait_for_line(socket, deadline, matcher, counter) do
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

  def count_and_print(lines, counter) do
    lines
    |> Enum.each(fn line ->
      count = Agent.get_and_update(counter, fn c -> {c, c + 1} end)
      IO.puts("#{count}: #{line}")
    end)
  end
end
