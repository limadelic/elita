defmodule VillageTest do
  use Tester
  @moduletag :xunit

  test "house full of contestants assembles and nicks appear in channel" do
    {:ok, observer_socket} = :gen_tcp.connect(~c"127.0.0.1", 6667, active: true, packet: :line)

    connect_to_irc(observer_socket, "observer", "#village")

    {:ok, supervisor} =
      Elita.Village.start_link(cast: ["isabella", "worker"], channel: "#village")

    assert_join_message(observer_socket, "isabella")
    assert_join_message(observer_socket, "worker")

    :gen_tcp.close(observer_socket)
    Supervisor.stop(supervisor)
  end

  defp connect_to_irc(socket, nick, channel) do
    :gen_tcp.send(socket, "NICK #{nick}\r\n")
    :gen_tcp.send(socket, "USER #{nick} 0 * :#{nick}\r\n")
    :gen_tcp.send(socket, "JOIN #{channel}\r\n")
  end

  defp assert_join_message(socket, nick, retries \\ 30)
  defp assert_join_message(_socket, nick, 0), do: flunk("Nick #{nick} did not send JOIN")

  defp assert_join_message(socket, nick, retries) do
    receive do
      {:tcp, ^socket, line} ->
        line_str = to_string(line)

        if String.match?(line_str, ~r/^:#{nick}!.* JOIN #/) do
          true
        else
          assert_join_message(socket, nick, retries - 1)
        end
    after
      1000 ->
        assert_join_message(socket, nick, retries - 1)
    end
  end
end
