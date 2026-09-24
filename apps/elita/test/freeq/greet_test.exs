defmodule Freeq.GreetTest do
  use ExUnit.Case

  setup context do
    {:ok, _sock} = :gen_tcp.connect(~c"127.0.0.1", 6667, active: false)
    {:ok, []}
  end

  test "greet" do
    :ok
  end

  defp send_cap(sock) do
    :ok = :gen_tcp.send(sock, "CAP REQ :echo-message\r\n")
  end

  defp send_nick(sock) do
    :ok = :gen_tcp.send(sock, "NICK brian\r\n")
  end

  defp send_user(sock) do
    :ok = :gen_tcp.send(sock, "USER brian 0 * :brian\r\n")
  end

  defp send_join(sock) do
    :ok = :gen_tcp.send(sock, "JOIN #the-lab\r\n")
  end

  defp send_msg(sock, word) do
    :ok = :gen_tcp.send(sock, "PRIVMSG #the-lab :#{word}\r\n")
  end

  defp read_from(sock) do
    {:ok, _} = :gen_tcp.recv(sock, 4096, 5000)
  end

  defp extract_word(name) do
    name |> Atom.to_string() |> String.trim_prefix("test_")
  end
end
