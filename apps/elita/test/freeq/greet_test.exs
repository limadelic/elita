defmodule Freeq.GreetTest do
  use ExUnit.Case

  import :gen_tcp, only: [connect: 3, recv: 3, send: 2, controlling_process: 2]
  import Regex, only: [compile!: 1, escape: 1]
  import String, only: [trim: 1]
  import Kernel, except: [send: 2]

  setup context do
    {:ok, sock} = connect(~c"127.0.0.1", 6667, packet: :line, active: false)
    login(sock)
    join(sock)
    greet(sock, word(context))

    pid = spawn(&owner/0)
    controlling_process(sock, pid)
    on_exit(fn -> tear(sock, pid) end)

    {:ok, socket: sock}
  end

  test "greet", %{socket: _sock} do
  end

  defp word(context) do
    context.test |> Atom.to_string()
  end

  defp login(sock) do
    send(sock, "CAP REQ :echo-message\r\n")
    send(sock, "NICK brian\r\n")
    send(sock, "USER brian 0 * :brian\r\n")
    send(sock, "CAP END\r\n")
    expect(sock, ~r/^:\S+ 001 brian /)
  end

  defp join(sock) do
    send(sock, "JOIN #the-lab\r\n")
    skip(sock, ~r/^:\S+ 366 brian #the-lab/)
  end

  defp greet(sock, word) do
    send(sock, "PRIVMSG #the-lab :#{word}\r\n")
    pattern = compile!("^:brian!\\S+ PRIVMSG #the-lab :#{escape(word)}\\r?$")
    expect(sock, pattern)
  end

  defp expect(sock, regex) do
    scan(sock, regex)
  end

  defp skip(sock, regex) do
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
    done(line =~ regex, sock, regex, line)
  end

  defp done(true, _sock, _regex, line) do
    line
  end

  defp done(false, sock, regex, _line) do
    scan(sock, regex)
  end

  defp owner do
    receive do
      :stop -> :ok
    end
  end

  defp tear(sock, pid) do
    part(sock)
    quit(sock)
    stop(pid)
  end

  defp stop(pid) do
    Kernel.send(pid, :stop)
  end

  defp part(sock) do
    send(sock, "PART #the-lab\r\n")
    pattern = compile!("^:brian!\\S+ PART #the-lab\\r?$")
    expect(sock, pattern)
  end

  defp quit(sock) do
    send(sock, "QUIT\r\n")
  end
end
