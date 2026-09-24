defmodule Brian do
  import :gen_tcp, only: [connect: 3, recv: 3, controlling_process: 2]
  import Regex, only: [compile!: 1, escape: 1]
  import String, only: [trim: 1]

  defmacro brian(test_name, do: block) do
    quote do
      test unquote(test_name), context do
        room = join("#the-lab")
        pause()
        say(room, name(context))
        on_exit(fn -> leave(room) end)
        Process.put(:brian_room, room)
        unquote(block)
      end
    end
  end

  def current_room do
    Process.get(:brian_room)
  end

  def join(channel) do
    sock = dial()
    enter(sock, channel)
    pid = spawn(&keeper/0)
    controlling_process(sock, pid)
    {sock, pid, channel}
  end

  defp dial do
    {:ok, sock} = connect(~c"127.0.0.1", 6667, packet: :line, active: false)
    auth(sock)
    sock
  end

  def say({sock, _, channel}, word) do
    write(sock, "PRIVMSG #{channel} :#{word}\r\n")
    pattern = compile!("^:brian!\\S+ PRIVMSG #{channel} :#{escape(word)}\\r?$")
    scan(sock, pattern)
    bubble(word)
  end

  def wait_join({sock, _, _}, agent, channel) do
    pattern = compile!("^:#{to_string(agent)}!\\S+ JOIN #{escape(channel)}")
    scan(sock, pattern)
  end

  defp bubble(text) do
    time = 4500 + String.length(text) * 30
    Process.sleep(time)
  end

  def leave({sock, pid, channel}) do
    part(sock, channel)
    quit(sock)
    send(pid, :stop)
  end

  def part(sock, channel) do
    write(sock, "PART #{channel}\r\n")
    pattern = compile!("^:brian!\\S+ PART #{channel}\\r?$")
    scan(sock, pattern)
  end

  def quit(sock) do
    write(sock, "QUIT\r\n")
  end

  def name(context) do
    context.test |> to_string()
  end

  def pause, do: Process.sleep(1000)

  defp auth(sock) do
    handshake(sock)
    scan(sock, compile!("^:\\S+ 001 brian "))
  end

  defp handshake(sock) do
    write(sock, "CAP REQ :echo-message\r\n")
    write(sock, "NICK brian\r\n")
    write(sock, "USER brian 0 * :brian\r\n")
    write(sock, "CAP END\r\n")
  end

  defp enter(sock, channel) do
    write(sock, "JOIN #{channel}\r\n")
    pattern = compile!("^:\\S+ 366 brian #{escape(channel)}")
    scan(sock, pattern)
  end

  def write(sock, line) do
    :gen_tcp.send(sock, line)
  end

  def scan(sock, regex) do
    {:ok, data} = recv(sock, 0, 5000)
    scan(sock, regex, to_string(data))
  end

  def scan(sock, regex, "PING " <> server) do
    write(sock, "PONG #{trim(server)}\r\n")
    scan(sock, regex)
  end

  def scan(sock, regex, line) do
    check(line =~ regex, sock, regex)
  end

  defp check(true, _sock, _regex), do: :ok
  defp check(false, sock, regex), do: scan(sock, regex)

  def keeper do
    receive do
      :stop -> :ok
    end
  end
end
