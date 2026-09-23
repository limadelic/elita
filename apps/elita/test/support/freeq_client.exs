defmodule FreeqTestClient do
  @opts [
    :binary,
    {:packet, :line},
    {:active, false},
    {:reuseaddr, true},
    {:nodelay, true}
  ]

  def connect do
    :gen_tcp.connect(~c"127.0.0.1", 6667, @opts)
  end

  def register_brian do
    auth()
    deadline = epoch() + 5000
    line(deadline, fn l -> String.contains?(l, "001") end)
    enter(deadline)
  end

  defp auth do
    socket = Process.get(:freeq_socket)
    :gen_tcp.send(socket, "NICK brian\r\n")
    :gen_tcp.send(socket, "USER brian 0 * :brian\r\n")
  end

  defp enter(deadline) do
    socket = Process.get(:freeq_socket)
    :gen_tcp.send(socket, "JOIN #the-lab\r\n")
    line(deadline, fn l -> String.contains?(l, " 366 ") end)
  end

  def wait_join(agent) do
    deadline = epoch() + 5000
    match = fn l -> String.contains?(l, agent) and String.contains?(l, "JOIN") end
    line(deadline, match)
  end

  def say(text) do
    socket = Process.get(:freeq_socket)
    :gen_tcp.send(socket, "PRIVMSG #the-lab :#{text}\r\n")
  end

  def hears(fragment) do
    deadline = epoch() + 5000
    scan(deadline, fragment)
  end

  defp epoch do
    System.monotonic_time(:millisecond)
  end

  defp line(deadline, match) do
    remaining = deadline - epoch()
    remaining > 0 || raise("Timeout waiting for matching line")
    fetch_line(deadline, match)
  end

  defp fetch_line(deadline, match) do
    socket = Process.get(:freeq_socket)
    result = :gen_tcp.recv(socket, 0, deadline - epoch())
    result |> handle_line(deadline, match)
  end

  defp handle_line({:ok, data}, deadline, match) do
    lines = String.split(data, "\r\n", trim: true)
    print(lines)
    found(lines, match) || line(deadline, match)
  end

  defp handle_line({:error, :timeout}, _, _) do
    raise "Timeout waiting for matching line"
  end

  defp handle_line({:error, reason}, _, _) do
    raise "Socket error: #{inspect(reason)}"
  end

  defp scan(deadline, fragment) do
    remaining = deadline - epoch()
    remaining > 0 || raise("Timeout waiting for fragment: #{fragment}")
    fetch_scan(deadline, fragment)
  end

  defp fetch_scan(deadline, fragment) do
    socket = Process.get(:freeq_socket)
    result = :gen_tcp.recv(socket, 0, deadline - epoch())
    result |> handle_scan(deadline, fragment)
  end

  defp handle_scan({:ok, data}, deadline, fragment) do
    lines = String.split(data, "\r\n", trim: true)
    print(lines)
    hunt(lines, fragment) || scan(deadline, fragment)
  end

  defp handle_scan({:error, :timeout}, _, fragment) do
    raise "Timeout waiting for fragment: #{fragment}"
  end

  defp handle_scan({:error, reason}, _, _) do
    raise "Socket error: #{inspect(reason)}"
  end

  defp found(lines, match) do
    Enum.find(lines, fn line -> match.(line) end)
  end

  defp hunt(lines, fragment) do
    lower = String.downcase(fragment)
    Enum.find(lines, fn line -> String.contains?(String.downcase(line), lower) end)
  end

  defp print(lines) do
    Enum.each(lines, fn line -> write(line) end)
  end

  defp write(line) do
    count = Process.get(:freeq_counter)
    Process.put(:freeq_counter, count + 1)
    IO.puts("#{count}: #{line}")
  end
end
