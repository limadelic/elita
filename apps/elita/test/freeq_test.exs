defmodule Elita.FreeqTest do
  use ExUnit.Case, async: false

  @tag :live
  test "joins channel and broadcasts messages" do
    {:ok, client_pid} = Elita.Freeq.start_link(nick: "isabella", channel: "#hobbs-cafe")

    {:ok, observer_socket} = :gen_tcp.connect(~c"127.0.0.1", 6667, active: true, packet: :line)

    connect_to_irc(observer_socket, "observer", "#hobbs-cafe")

    Elita.Freeq.say(client_pid, "hello from elita")

    assert_message_received(observer_socket, "hello from elita")

    :gen_tcp.close(observer_socket)
  end

  defp connect_to_irc(socket, nick, channel) do
    :gen_tcp.send(socket, "NICK #{nick}\r\n")
    :gen_tcp.send(socket, "USER #{nick} 0 * :#{nick}\r\n")
    :gen_tcp.send(socket, "JOIN #{channel}\r\n")
  end

  defp assert_message_received(socket, text, retries \\ 10)
  defp assert_message_received(_socket, _text, 0), do: flunk("Message not received")

  defp assert_message_received(socket, text, retries) do
    receive do
      {:tcp, ^socket, line} ->
        if String.contains?(to_string(line), text) do
          true
        else
          assert_message_received(socket, text, retries - 1)
        end
    after
      1000 ->
        flunk("Timeout waiting for message")
    end
  end
end
