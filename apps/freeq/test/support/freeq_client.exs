defmodule FreeqTestClient do
  import Freeq.Batch, only: [absorb: 1]
  import Freeq.Said, only: [matches?: 4]
  @opts [:binary, {:packet, :line}, {:active, false}, {:reuseaddr, true}, {:nodelay, true}]
  @timeout 5000
  @driver "brian"

  def connect do
    port = String.to_integer(System.get_env("FREEQ_PORT", "6667"))
    :gen_tcp.connect(~c"127.0.0.1", port, @opts)
  end

  def register_brian do
    request_caps()
    send_line("NICK brian")
    send_line("USER brian 0 * :brian")
    await("001", &String.contains?(&1, " 001 "))
    send_line("JOIN #the-lab")
    await("366", &String.contains?(&1, " 366 "))
    Process.put(:freeq_transcript, [])
  end

  defp request_caps do
    send_line("CAP REQ :batch draft/multiline message-tags extended-join")
    send_line("CAP END")
  end

  def wait_join(agent) do
    processed_line = await("#{agent} JOIN", &joined(&1, agent))
    lookup_raw_line(processed_line)
  end

  defp lookup_raw_line(processed_line) do
    pairs = Process.get(:freeq_line_map, [])
    case Enum.find(pairs, fn {proc, _} -> proc == processed_line end) do
      {_, raw} -> raw
      nil -> processed_line
    end
  end

  def say(text), do: send_line("PRIVMSG #the-lab :#{text}")

  def hears(fragment), do: await(fragment, &holds(&1, fragment))

  defp joined(line, agent), do: String.contains?(line, agent) and String.contains?(line, "JOIN")

  defp holds(line, fragment),
    do: String.contains?(String.downcase(line), String.downcase(fragment))

  defp socket, do: Process.get(:freeq_socket)

  defp send_line(text), do: :gen_tcp.send(socket(), "#{text}\r\n")

  defp epoch, do: System.monotonic_time(:millisecond)

  defp await(what, match), do: hunt(what, match, epoch() + @timeout)

  defp hunt(what, match, deadline) do
    read(what, deadline) |> Enum.find(match) || hunt(what, match, deadline)
  end

  defp read(what, deadline) do
    left = deadline - epoch()
    left > 0 || raise("timeout waiting for #{what}")
    raw = :gen_tcp.recv(socket(), 0, left) |> lines(what)
    processed = raw |> absorb() |> record()
    Process.put(:freeq_raw_lines, (Process.get(:freeq_raw_lines, []) ++ raw))

    pairs = Enum.zip(processed, raw)
    all_pairs = Process.get(:freeq_line_map, [])
    Process.put(:freeq_line_map, all_pairs ++ pairs)

    processed
  end

  defp record(lines) do
    Process.put(:freeq_transcript, Process.get(:freeq_transcript, []) ++ lines)
    lines
  end

  defp lines({:ok, data}, _what), do: String.split(data, "\r\n", trim: true)
  defp lines({:error, :timeout}, what), do: raise("timeout waiting for #{what}")
  defp lines({:error, reason}, _what), do: raise("socket error: #{inspect(reason)}")

  def reply(agent) do
    name = to_string(agent)
    await("reply from #{name}", &from(&1, name)) |> text()
  end

  defdelegate said?(from, to, fragment), to: Freeq.Said

  def wait_said?(from, to, fragment) do
    said?(from, to, fragment) or found(from, to, fragment)
  end

  defp found(from, to, fragment) do
    await("#{from} to #{to}: #{fragment}", &matches?(&1, from, to, fragment))
    true
  end

  defp from(line, agent) do
    String.starts_with?(line, ":#{agent}!") and
      String.contains?(line, "PRIVMSG #the-lab :@#{@driver} ")
  end

  defp text(line), do: line |> String.split(" :@#{@driver} ", parts: 2) |> List.last()
end
