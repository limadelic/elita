defmodule Freeq.GreetTest do
  use ExUnit.Case

  setup context do
    {:ok, sock} = :gen_tcp.connect(~c"127.0.0.1", 6667, packet: :line, active: false)
    login(sock)
    join(sock)
    greet(sock, extract_word(context.test))
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
    discard_until(sock, ~r/^:\S+ 366 brian #the-lab/)
  end

  defp greet(sock, word) do
    :gen_tcp.send(sock, "PRIVMSG #the-lab :#{word}\r\n")
    pattern = Regex.compile!("^:brian!\\S+ PRIVMSG #the-lab :#{Regex.escape(word)}\\r?$")
    expect(sock, pattern)
  end

  defp expect(sock, regex) do
    {:ok, data} = :gen_tcp.recv(sock, 0, 5000)
    line = to_string(data)
    read_until(sock, regex, line)
  end

  defp discard_until(sock, regex) do
    {:ok, data} = :gen_tcp.recv(sock, 0, 5000)
    line = to_string(data)
    handle_discard(sock, regex, line)
  end

  defp handle_discard(sock, regex, "PING " <> server) do
    :gen_tcp.send(sock, "PONG #{String.trim(server)}\r\n")
    discard_until(sock, regex)
  end

  defp handle_discard(sock, regex, line) do
    line
    |> check_discard_match(regex)
    |> match_discard(sock, regex)
  end

  defp check_discard_match(line, regex) do
    Regex.match?(regex, line)
  end

  defp match_discard(true, _sock, _regex) do
    :ok
  end

  defp match_discard(false, sock, regex) do
    discard_until(sock, regex)
  end

  defp read_until(sock, regex, "PING " <> server) do
    :gen_tcp.send(sock, "PONG #{String.trim(server)}\r\n")
    expect(sock, regex)
  end

  defp read_until(sock, regex, line) do
    line
    |> check_read_match(regex)
    |> match_read(sock, regex, line)
  end

  defp check_read_match(line, regex) do
    Regex.match?(regex, line)
  end

  defp match_read(true, _sock, _regex, line) do
    line
  end

  defp match_read(false, sock, regex, _line) do
    expect(sock, regex)
  end

  defp extract_word(name) do
    name |> Atom.to_string() |> String.split(~r/[ _]/) |> List.last()
  end
end
