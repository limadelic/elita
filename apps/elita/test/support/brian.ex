defmodule Brian do
  import :gen_tcp, only: [connect: 3, recv: 3, controlling_process: 2]
  import Regex, only: [compile!: 1, escape: 1]
  import String, only: [trim: 1]
  import Kernel

  defmacro brian(test_name, do: block) do
    quote do
      brian_connection = join("#the-lab")
      say(brian_connection, unquote(test_name))
      on_exit(fn -> leave(brian_connection) end)
      unquote(block)
    end
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
  end

  def leave({sock, pid, channel}) do
    part(sock, channel)
    quit(sock)
    send(pid, :stop)
  end

  def name(context) do
    context.test |> to_string()
  end

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

  defp part(sock, channel) do
    write(sock, "PART #{channel}\r\n")
    pattern = compile!("^:brian!\\S+ PART #{channel}\\r?$")
    scan(sock, pattern)
  end

  defp quit(sock) do
    write(sock, "QUIT\r\n")
  end

  defp write(sock, line) do
    :gen_tcp.send(sock, line)
  end

  defp scan(sock, regex) do
    {:ok, data} = recv(sock, 0, 5000)
    scan(sock, regex, to_string(data))
  end

  defp scan(sock, regex, "PING " <> server) do
    write(sock, "PONG #{trim(server)}\r\n")
    scan(sock, regex)
  end

  defp scan(sock, regex, line) do
    check(line =~ regex, sock, regex)
  end

  defp check(true, _sock, _regex), do: :ok
  defp check(false, sock, regex), do: scan(sock, regex)

  defp keeper do
    receive do
      :stop -> :ok
    end
  end
end
