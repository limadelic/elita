defmodule Freeq.GreetTest do
  use ExUnit.Case

  setup context do
    {:ok, sock} = :gen_tcp.connect(~c"127.0.0.1", 6667, packet: :line, active: false)
    login(sock)
    join(sock)
    greet(sock, word(context.test))
    {:ok, socket: sock}
  end

  test "greet" do
    :ok
  end

  defp login(sock) do
    :gen_tcp.send(sock, "CAP REQ :echo-message\r\n")
    :gen_tcp.send(sock, "NICK brian\r\n")
    :gen_tcp.send(sock, "USER brian 0 * :brian\r\n")
    :gen_tcp.send(sock, "CAP END\r\n")
    expect(sock, ~r/^:\S+ 001 brian /)
  end

  defp join(sock) do
    :gen_tcp.send(sock, "JOIN #the-lab\r\n")
    skip(sock, ~r/^:\S+ 366 brian #the-lab/)
  end

  defp greet(sock, word) do
    :gen_tcp.send(sock, "PRIVMSG #the-lab :#{word}\r\n")
    pattern = Regex.compile!("^:brian!\\S+ PRIVMSG #the-lab :#{Regex.escape(word)}\\r?$")
    expect(sock, pattern)
  end

  defp expect(sock, regex) do
    scan(sock, regex)
  end

  defp skip(sock, regex) do
    scan(sock, regex)
  end

  defp scan(sock, regex) do
    {:ok, data} = :gen_tcp.recv(sock, 0, 5000)
    scan(sock, regex, to_string(data))
  end

  defp scan(sock, regex, "PING " <> server) do
    :gen_tcp.send(sock, "PONG #{String.trim(server)}\r\n")
    scan(sock, regex)
  end

  defp scan(sock, regex, line) do
    matched = Regex.match?(regex, line)
    done(matched, sock, regex, line)
  end

  defp done(true, _sock, _regex, line) do
    line
  end

  defp done(false, sock, regex, _line) do
    scan(sock, regex)
  end

  defp word(name) do
    name |> Atom.to_string() |> String.split(~r/[ _]/) |> List.last()
  end
end
