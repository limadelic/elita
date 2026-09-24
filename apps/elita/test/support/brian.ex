defmodule Brian do
  import :gen_tcp, only: [connect: 3, recv: 3, send: 2, controlling_process: 2]
  import Regex, only: [compile!: 1, escape: 1]
  import String, only: [trim: 1]
  import Kernel, except: [send: 2]

  def join(channel) do
    sock = setup()
    enter(sock, channel)
    pid = spawn(&keeper/0)
    controlling_process(sock, pid)
    {sock, pid}
  end

  defp setup do
    {:ok, sock} = connect(~c"127.0.0.1", 6667, packet: :line, active: false)
    auth(sock)
    sock
  end

  def say(handle, word) do
    {sock, _} = handle
    send(sock, "PRIVMSG #the-lab :#{word}\r\n")
    pattern = compile!("^:brian!\\S+ PRIVMSG #the-lab :#{escape(word)}\\r?$")
    listen(sock, pattern)
  end

  def leave(handle) do
    {sock, pid} = handle
    part(sock)
    quit(sock)
    stop(pid)
  end

  def name(context) do
    context.test |> to_string()
  end

  defp auth(sock) do
    handshake(sock)
    listen(sock, compile!("^:\\S+ 001 brian "))
  end

  defp handshake(sock) do
    send(sock, "CAP REQ :echo-message\r\n")
    send(sock, "NICK brian\r\n")
    send(sock, "USER brian 0 * :brian\r\n")
    send(sock, "CAP END\r\n")
  end

  defp enter(sock, channel) do
    send(sock, "JOIN #{channel}\r\n")
    pattern = compile!("^:\\S+ 366 brian #{Regex.escape(channel)}")
    scan(sock, pattern)
  end

  defp part(sock) do
    send(sock, "PART #the-lab\r\n")
    pattern = compile!("^:brian!\\S+ PART #the-lab\\r?$")
    listen(sock, pattern)
  end

  defp quit(sock) do
    send(sock, "QUIT\r\n")
  end

  defp listen(sock, regex) do
    scan(sock, regex)
  end

  defp scan(sock, regex) do
    {:ok, data} = recv(sock, 0, 5000)
    scan(sock, regex, to_string(data))
  end

  defp scan(sock, regex, "PING " <> server) do
    send(sock, "PONG #{trim(server)}\r\n")
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

  defp stop(pid) do
    Kernel.send(pid, :stop)
  end
end
