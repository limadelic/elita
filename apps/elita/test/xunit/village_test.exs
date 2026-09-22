defmodule VillageTest do
  use Tester
  @moduletag :xunit

  test "house full of contestants assembles and nicks appear in channel" do
    {:ok, observer_socket} = :gen_tcp.connect(~c"127.0.0.1", 6667, active: true, packet: :line)

    connect_to_irc(observer_socket, "observer", "#village")

    {:ok, _supervisor} = Elita.Village.start_link(cast: ["alice", "bob"], channel: "#village")

    assert_nick_joined(observer_socket, "alice")
    assert_nick_joined(observer_socket, "bob")

    :gen_tcp.close(observer_socket)
  end

  defp connect_to_irc(socket, nick, channel) do
    :gen_tcp.send(socket, "NICK #{nick}\r\n")
    :gen_tcp.send(socket, "USER #{nick} 0 * :#{nick}\r\n")
    :gen_tcp.send(socket, "JOIN #{channel}\r\n")
  end

  defp assert_nick_joined(socket, nick, retries \\ 30)
  defp assert_nick_joined(_socket, nick, 0), do: flunk("Nick #{nick} did not join")

  defp assert_nick_joined(socket, nick, retries) do
    receive do
      {:tcp, ^socket, line} ->
        if String.contains?(to_string(line), nick) do
          true
        else
          assert_nick_joined(socket, nick, retries - 1)
        end
    after
      1000 ->
        assert_nick_joined(socket, nick, retries - 1)
    end
  end
end
