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

  @tag cassette: "village_ask"
  test "one villager asks another in channel" do
    {:ok, observer_socket} = :gen_tcp.connect(~c"127.0.0.1", 6667, active: true, packet: :line)

    connect_to_irc(observer_socket, "observer", "#village")

    {:ok, supervisor} =
      Elita.Village.start_link(cast: ["isabella", "worker"], channel: "#village")

    assert_join_message(observer_socket, "isabella")
    assert_join_message(observer_socket, "worker")

    isabella_client = Elita.Village.fetch(supervisor, "isabella")
    Elita.Freeq.tell(isabella_client, "worker", "what time is the party?")

    assert_answer_received(observer_socket, "worker", "party")

    :gen_tcp.close(observer_socket)
    Supervisor.stop(supervisor)
  end

  @tag cassette: "village_tick"
  test "clock ticks and each villager responds with unique answer" do
    Application.put_env(:elita, :clock_override, "2025-07-07T10:30:00")

    {:ok, observer_socket} = :gen_tcp.connect(~c"127.0.0.1", 6667, active: true, packet: :line)
    connect_to_irc(observer_socket, "observer", "#village")

    {:ok, supervisor} =
      Elita.Village.start_link(cast: ["clock", "isabella", "worker"], channel: "#village")

    assert_join_message(observer_socket, "clock")
    assert_join_message(observer_socket, "isabella")
    assert_join_message(observer_socket, "worker")

    Elita.Tick.tick(supervisor)

    messages = collect_messages(observer_socket, 30)

    assert Enum.any?(messages, &String.contains?(&1, "isabella ready")),
           "Isabella's answer not received"

    assert Enum.any?(messages, &String.contains?(&1, "worker standing")),
           "Worker's answer not received"

    :gen_tcp.close(observer_socket)
    Supervisor.stop(supervisor)
    Application.delete_env(:elita, :clock_override)
  end

  @tag cassette: "village_tick"
  test "tick works with villagers added via environment" do
    Application.put_env(:elita, :clock_override, "2025-07-07T10:30:00")

    {:ok, observer_socket} = :gen_tcp.connect(~c"127.0.0.1", 6667, active: true, packet: :line)
    connect_to_irc(observer_socket, "observer", "#village")

    cast = ["clock", "isabella", "worker", "tom", "maria"]
    {:ok, supervisor} = Elita.Village.start_link(cast: cast, channel: "#village")

    assert_join_message(observer_socket, "clock")
    assert_join_message(observer_socket, "isabella")
    assert_join_message(observer_socket, "worker")
    assert_join_message(observer_socket, "tom")
    assert_join_message(observer_socket, "maria")

    clock_client = Elita.Village.fetch(supervisor, "clock")
    assert clock_client != nil, "Clock should be available in supervisor"

    Elita.Tick.tick(supervisor)

    messages = collect_messages(observer_socket, 30)

    assert Enum.any?(messages, &String.contains?(&1, "isabella ready")),
           "Isabella's answer not received"

    assert Enum.any?(messages, &String.contains?(&1, "worker standing")),
           "Worker's answer not received"

    :gen_tcp.close(observer_socket)
    Supervisor.stop(supervisor)
    Application.delete_env(:elita, :clock_override)
  end

  defp assert_answer_received(socket, from_nick, contains, retries \\ 30)

  defp assert_answer_received(_socket, _from_nick, _contains, 0) do
    flunk("Answer not received")
  end

  defp assert_answer_received(socket, from_nick, contains, retries) do
    receive do
      {:tcp, ^socket, line} ->
        line_str = to_string(line)

        if String.match?(line_str, ~r/:#{from_nick}!/) and
             String.contains?(line_str, contains) do
          true
        else
          assert_answer_received(socket, from_nick, contains, retries - 1)
        end
    after
      1000 ->
        assert_answer_received(socket, from_nick, contains, retries - 1)
    end
  end

  defp collect_messages(socket, retries, acc \\ [])

  defp collect_messages(_socket, 0, acc) do
    acc
  end

  defp collect_messages(socket, retries, acc) do
    receive do
      {:tcp, ^socket, line} ->
        collect_messages(socket, retries - 1, [to_string(line) | acc])
    after
      500 ->
        acc
    end
  end
end
