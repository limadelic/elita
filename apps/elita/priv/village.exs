defmodule Village do
  def start do
    cast = env("CAST") |> parse_cast()
    channel = env("CHANNEL", "#village")

    check_live_or_tape!()

    cast_with_clock = cast ++ ["clock"]
    {:ok, sup} = Elita.Village.start_link(cast: cast_with_clock, channel: channel)

    IO.puts("Village booted: #{Enum.join(cast, ", ")} on #{channel}")

    spawn_observer(channel)
    input_loop(sup, cast, 0)
  end

  defp env(key), do: System.get_env(key)
  defp env(key, default), do: System.get_env(key, default)

  defp parse_cast(nil) do
    ["isabella", "worker", "tom", "maria", "sam", "ruth", "jake", "emma", "mayor", "nurse"]
  end

  defp parse_cast(str) do
    str |> String.split(",") |> Enum.map(&String.trim/1)
  end

  defp check_live_or_tape! do
    live = env("LIVE")
    tape = env("TAPE")
    tape_on_miss = env("TAPE_ON_MISS")

    unless live == "1" or tape == "rec" or tape_on_miss == "live" do
      IO.puts("ERROR: Set LIVE=1 or TAPE=rec CASSETTE=<name> or TAPE_ON_MISS=live")
      System.halt(1)
    end
  end

  defp spawn_observer(channel) do
    spawn(fn -> observer(channel) end)
  end

  defp observer(channel) do
    {:ok, socket} = :gen_tcp.connect(~c"127.0.0.1", 6667, active: true, packet: :line)

    send_line(socket, "NICK producer")
    send_line(socket, "USER producer 0 * :Producer")
    send_line(socket, "JOIN #{channel}")

    listen(socket)
  end

  defp listen(socket) do
    receive do
      {:tcp, ^socket, line} ->
        line |> to_string() |> String.trim_trailing("\r\n") |> handle_line(socket)
        listen(socket)

      {:tcp_closed, ^socket} ->
        :ok
    after
      120000 ->
        listen(socket)
    end
  end

  defp handle_line(<<":", _::binary>> = msg, _socket) do
    case parse_privmsg(msg) do
      {:privmsg, speaker, text} ->
        IO.puts("#{speaker} | #{text}")

      _ ->
        :ok
    end
  end

  defp handle_line("PING " <> server, socket) do
    send_line(socket, "PONG #{String.trim_trailing(server, "\r\n")}")
  end

  defp handle_line(_msg, _socket), do: :ok

  defp parse_privmsg(line) do
    case String.split(line, " PRIVMSG ", parts: 2) do
      [source, rest] ->
        nick = source |> String.trim_leading(":") |> String.split("!") |> hd()

        case String.split(rest, " :", parts: 2) do
          [_channel, text] ->
            {:privmsg, nick, text}

          _ ->
            :error
        end

      _ ->
        :error
    end
  end

  defp send_line(socket, line) do
    :gen_tcp.send(socket, "#{line}\r\n")
  end

  defp input_loop(sup, cast, count) do
    case IO.gets("") do
      :eof ->
        System.halt(0)

      {:error, _} ->
        System.halt(1)

      input ->
        case String.trim(input) do
          "quit" ->
            IO.puts("Stopping village")
            System.halt(0)

          "tick" ->
            Elita.Tick.tick(sup)
            new_count = count + length(cast)
            IO.puts("Questions sent: #{new_count}")
            input_loop(sup, cast, new_count)

          "" ->
            input_loop(sup, cast, count)

          cmd ->
            IO.puts("Unknown command: #{cmd}")
            input_loop(sup, cast, count)
        end
    end
  end

end

Village.start()
