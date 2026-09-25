defmodule FreeqTestClient do
  import Freeq.Batch, only: [absorb: 1, strip: 1]
  import Freeq.Said, only: [matches?: 4]
  @opts [:binary, {:packet, :line}, {:active, false}, {:reuseaddr, true}, {:nodelay, true}]
  @timeout 5000
  @driver "brian"

  def connect do
    {:ok, port_string} = System.fetch_env("FREEQ_PORT")
    port = String.to_integer(port_string)
    :gen_tcp.connect(~c"127.0.0.1", port, @opts)
  rescue
    MatchError -> raise("FREEQ_PORT not set")
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
    await("#{agent} JOIN", &joined(&1, agent))
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
    processed = raw |> Enum.flat_map(&feed_one/1) |> record()
    processed
  end

  defp feed_one(raw) do
    result = absorb([raw])
    case result do
      [stripped] -> if stripped == strip(raw), do: [raw], else: [stripped]
      other -> other
    end
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
    stripped = strip(line)
    String.starts_with?(stripped, ":#{agent}!") and
      String.contains?(line, "PRIVMSG #the-lab :@#{@driver} ")
  end

  defp text(line), do: line |> String.split(" :@#{@driver} ", parts: 2) |> List.last()
end
