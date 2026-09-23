defmodule FreeqTestClient do
  import String, only: [split: 2, split: 3, starts_with?: 2]
  import Enum, only: [find: 2, any?: 2]
  import Process, only: [get: 2, put: 2]
  import Freeq.Batch, only: [assemble: 1]
  import Freeq.Match

  @opts [:binary, {:packet, :line}, {:active, false}, {:reuseaddr, true}, {:nodelay, true}]
  @timeout 5000

  def connect, do: :gen_tcp.connect(~c"127.0.0.1", 6667, @opts)

  def register_brian do
    send_line("CAP REQ :batch draft/multiline")
    send_line("CAP END")
    send_line("NICK brian")
    send_line("USER brian 0 * :brian")
    await("001", &caps?/1)
    send_line("JOIN #the-lab")
    await("366", &join?/1)
    Process.put(:freeq_transcript, [])
  end

  def wait_join(agent) do
    await("#{agent} JOIN", &connects(&1, agent))
  end

  def say(text) do
    send_line("PRIVMSG #the-lab :#{text}")
  end

  def hears(fragment) do
    await(fragment, &holds(&1, fragment))
  end

  def reply(agent) do
    name = to_string(agent)
    await("reply from #{name}", &from_peer(&1, name)) |> text()
  end

  def said?(from, to, fragment) do
    transcript = Process.get(:freeq_transcript, [])
    said?(from, to, fragment, transcript)
  end

  defp socket, do: Process.get(:freeq_socket)

  defp send_line(text) do
    :gen_tcp.send(socket(), "#{text}\r\n")
  end

  defp epoch, do: System.monotonic_time(:millisecond)

  defp await(what, match) do
    hunt(what, match, epoch() + @timeout)
  end

  defp hunt(what, match, deadline) do
    lines = fetch(what, deadline) |> assemble()
    find(lines, match) || hunt(what, match, deadline)
  end

  defp fetch(what, deadline) do
    left = deadline - epoch()
    ok_timeout?(left, what)
    :gen_tcp.recv(socket(), 0, left) |> recv(what) |> store()
  end

  defp ok_timeout?(left, what) do
    left > 0 || raise("timeout waiting for #{what}")
  end

  defp store(lines) do
    put(:freeq_transcript, get(:freeq_transcript, []) ++ lines)
    lines
  end

  defp recv({:ok, data}, _what) do
    split(data, "\r\n", trim: true)
  end

  defp recv({:error, :timeout}, what) do
    raise("timeout waiting for #{what}")
  end

  defp recv({:error, reason}, _what) do
    raise("socket error: #{inspect(reason)}")
  end
end
