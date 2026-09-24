defmodule Freeq.GreetTest do
  use ExUnit.Case

  import :gen_tcp, only: [connect: 3, recv: 3, send: 2, controlling_process: 2]
  import Regex, only: [compile!: 1, escape: 1]
  import String, only: [trim: 1]
  import Kernel, except: [send: 2]

  setup _context do
    {:ok, sock} = connect(~c"127.0.0.1", 6667, packet: :line, active: false)
    login(sock)
    join(sock)
    greet(sock, "hello")

    keeper = spawn(fn -> keeper(sock) end)
    controlling_process(sock, keeper)

    on_exit(fn ->
      ref = make_ref()
      Process.send(keeper, {:teardown, self(), ref}, [])

      receive do
        {:ok, ^ref} -> :ok
        {:error, ^ref, e} -> raise e
      after
        10000 -> :ok
      end
    end)

    {:ok, socket: sock}
  end

  test "greet", %{socket: _sock} do
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

  defp keeper(sock) do
    receive do
      {:teardown, caller, ref} ->
        try do
          part(sock)
          quit(sock)
          Process.send(caller, {:ok, ref}, [])
        rescue
          e -> Process.send(caller, {:error, ref, e}, [])
        end
    end
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
