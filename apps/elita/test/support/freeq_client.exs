defmodule FreeqTestClient do
  @opts [:binary, {:packet, :line}, {:active, false}, {:reuseaddr, true}, {:nodelay, true}]
  @timeout 5000

  def connect, do: :gen_tcp.connect(~c"127.0.0.1", 6667, @opts)

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
    send_line("CAP REQ :batch draft/multiline")
    send_line("CAP END")
  end

  def wait_join(agent), do: await("#{agent} JOIN", &joined(&1, agent))

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
    :gen_tcp.recv(socket(), 0, left) |> lines(what) |> record()
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

  def said?(from, to, fragment) do
    transcript = Process.get(:freeq_transcript, [])
    Enum.any?(transcript, &matches?(&1, from, to, fragment))
  end

  defp matches?(line, from, to, fragment) do
    String.starts_with?(line, ":#{from}!") and
      String.contains?(line, "PRIVMSG #the-lab :") and
      addressee_match(line, to, fragment)
  end

  defp addressee_match(line, to, fragment) do
    case String.split(line, "PRIVMSG #the-lab :", parts: 2) do
      [_, message] -> starts_with?(message, to) and includes?(message, fragment)
      _ -> false
    end
  end

  defp starts_with?(message, to), do: String.starts_with?(message, "#{to}: ")

  defp includes?(message, fragment),
    do: String.contains?(String.downcase(message), String.downcase(fragment))

  defp from(line, agent),
    do: String.starts_with?(line, ":#{agent}!") and String.contains?(line, "PRIVMSG")

  defp text(line), do: line |> String.split(" :", parts: 2) |> List.last()
end
