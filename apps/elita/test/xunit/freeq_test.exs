defmodule FreeqTest do
  use Tester
  @moduletag :xunit

  @tag :live
  @tag cassette: "freeq_hello"
  test "joins channel and broadcasts messages" do
    spawn(:isabella)

    {:ok, client_pid} = Elita.Freeq.start_link(agent: "isabella", channel: "#hobbs-cafe")

    {:ok, observer_socket} = :gen_tcp.connect(~c"127.0.0.1", 6667, active: true, packet: :line)

    connect_to_irc(observer_socket, "observer", "#hobbs-cafe")

    Elita.Freeq.say(client_pid, "hello from elita")

    assert_message_received(observer_socket, "hello from elita")

    :gen_tcp.close(observer_socket)
  end

  @tag :integration
  @tag :live
  @tag cassette: "freeq_isabella"
  test "agent answers channel question" do
    {:ok, _} = Elita.Freeq.start_link(agent: "isabella", channel: "#hobbs-cafe")

    {:ok, observer_socket} = :gen_tcp.connect(~c"127.0.0.1", 6667, active: true, packet: :line)

    connect_to_irc(observer_socket, "observer", "#hobbs-cafe")

    spawn(:isabella)

    Process.sleep(500)

    :gen_tcp.send(observer_socket, "PRIVMSG #hobbs-cafe :isabella: when is the party?\r\n")

    assert_message_received(observer_socket, ~w(:isabella! party tomorrow Valentine), 30_000)

    :gen_tcp.close(observer_socket)
  end

  defp connect_to_irc(socket, nick, channel) do
    :gen_tcp.send(socket, "NICK #{nick}\r\n")
    :gen_tcp.send(socket, "USER #{nick} 0 * :#{nick}\r\n")
    :gen_tcp.send(socket, "JOIN #{channel}\r\n")
  end

  defp assert_message_received(socket, text, retries \\ 10)
  defp assert_message_received(_socket, _text, 0), do: flunk("Message not received")

  defp assert_message_received(socket, keywords, retries) when is_list(keywords) do
    receive do
      {:tcp, ^socket, line} ->
        line_str = to_string(line)

        if Enum.any?(keywords, &String.contains?(line_str, &1)) do
          true
        else
          assert_message_received(socket, keywords, retries - 1)
        end
    after
      1000 ->
        flunk("Timeout waiting for message")
    end
  end

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

  test "answers questions without blocking socket" do
    stub_asker = fn _agent, _msg ->
      Process.sleep(300)
      "delayed answer"
    end

    {:ok, client_pid} =
      Elita.Freeq.start_link(agent: "isabella", channel: "#test", ask: stub_asker)

    {:ok, observer_socket} = :gen_tcp.connect(~c"127.0.0.1", 6667, active: true, packet: :line)

    connect_to_irc(observer_socket, "observer", "#test")

    :gen_tcp.send(observer_socket, "PRIVMSG #test :isabella: hello?\r\n")

    Process.sleep(50)

    :gen_tcp.send(observer_socket, ":server PING\r\n")

    assert_message_received(observer_socket, "PONG", 20)
    assert_message_received(observer_socket, "delayed answer", 20)

    :gen_tcp.close(observer_socket)
  end
end
