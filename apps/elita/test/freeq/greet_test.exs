defmodule Freeq.GreetTest do
  use ExUnit.Case

  setup context do
    {:ok, sock} = :gen_tcp.connect(~c"127.0.0.1", 6667, packet: :line, active: false)
    send_cap(sock)
    send_nick(sock)
    send_user(sock)
    send_cap_end(sock)
    _ = read_until(sock, "001")
    send_join(sock)
    line = read_until(sock, "JOIN")
    assert String.contains?(line, "brian")
    word = extract_word(context.test)
    send_privmsg(sock, word)
    line = read_until(sock, "PRIVMSG")
    assert String.contains?(line, "brian")
    {:ok, socket: sock}
  end

  test "greet" do
    :ok
  end

  defp send_cap(sock) do
    :gen_tcp.send(sock, "CAP REQ :echo-message\r\n")
  end

  defp send_nick(sock) do
    :gen_tcp.send(sock, "NICK brian\r\n")
  end

  defp send_user(sock) do
    :gen_tcp.send(sock, "USER brian 0 * :brian\r\n")
  end

  defp send_cap_end(sock) do
    :gen_tcp.send(sock, "CAP END\r\n")
  end

  defp send_join(sock) do
    :gen_tcp.send(sock, "JOIN #the-lab\r\n")
  end

  defp send_privmsg(sock, word) do
    :gen_tcp.send(sock, "PRIVMSG #the-lab :#{word}\r\n")
  end

  defp read_until(sock, marker) do
    {:ok, data} = :gen_tcp.recv(sock, 0, 5000)
    check_line(sock, to_string(data), marker)
  end

  defp check_line(sock, line, marker) do
    if String.contains?(line, marker),
      do: line,
      else:
        (
          handle_ping(sock, line)
          read_until(sock, marker)
        )
  end

  defp handle_ping(sock, line) do
    String.starts_with?(line, "PING") && send_pong(sock, line)
  end

  defp send_pong(sock, line) do
    [_, server] = String.split(line, " ", parts: 2)
    :gen_tcp.send(sock, "PONG #{String.trim(server)}\r\n")
  end

  defp extract_word(name) do
    name |> Atom.to_string() |> String.split(~r/[ _]/) |> List.last()
  end
end
