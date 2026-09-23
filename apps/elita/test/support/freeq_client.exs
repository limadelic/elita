defmodule FreeqTestClient do
  @opts [:binary, {:packet, :line}, {:active, false}, {:reuseaddr, true}, {:nodelay, true}]
  @timeout 5000

  def connect, do: :gen_tcp.connect(~c"127.0.0.1", 6667, @opts)

  def register_brian do
    send_line("CAP REQ batch draft/multiline")
    await("CAP", &String.contains?(&1, " CAP "))
    send_line("CAP END")
    send_line("NICK brian")
    send_line("USER brian 0 * :brian")
    await("001", &String.contains?(&1, " 001 "))
    send_line("JOIN #the-lab")
    await("366", &String.contains?(&1, " 366 "))
    Process.put(:freeq_transcript, [])
    Process.put(:freeq_batches, %{})
  end

  def wait_join(agent), do: await("#{agent} JOIN", &joined(&1, agent))

  def say(text), do: send_line("PRIVMSG #the-lab :#{text}")

  def hears(fragment), do: await(fragment, &holds(&1, fragment))

  defp joined(line, agent), do: String.contains?(line, agent) and String.contains?(line, "JOIN")

  defp holds(line, fragment),
    do: String.contains?(String.downcase(line), String.downcase(fragment))

  defp socket, do: Process.get(:freeq_socket)

  defp send_line(text), do: :gen_tcp.send(socket(), "#{text}\r\n")

  defp epoch, do: System.monotonic_time(:millisecond)

  defp await(what, match), do: hunt(what, match, epoch() + @timeout)

  defp hunt(what, match, deadline) do
    read(what, deadline) |> Enum.find(match) || hunt(what, match, deadline)
  end

  defp read(what, deadline) do
    left = deadline - epoch()
    left > 0 || raise("timeout waiting for #{what}")
    :gen_tcp.recv(socket(), 0, left) |> lines(what) |> process_batches() |> record()
  end

  defp record(lines) do
    Process.put(:freeq_transcript, Process.get(:freeq_transcript, []) ++ lines)
    lines
  end

  defp lines({:ok, data}, _what), do: String.split(data, "\r\n", trim: true)
  defp lines({:error, :timeout}, what), do: raise("timeout waiting for #{what}")
  defp lines({:error, reason}, _what), do: raise("socket error: #{inspect(reason)}")

  defp process_batches(lines) do
    Enum.reduce(lines, [], &handle_batch_line/2) |> Enum.reverse()
  end

  defp handle_batch_line("BATCH +" <> rest, acc) do
    [id, type, target | _] = String.split(rest)
    batches = Process.get(:freeq_batches, %{})
    Process.put(:freeq_batches, Map.put(batches, id, {type, target, []}))
    acc
  end

  defp handle_batch_line("BATCH -" <> id, acc) do
    bid = String.trim(id)
    batches = Process.get(:freeq_batches, %{})

    case Map.pop(batches, bid) do
      {{_t, _tgt, lines}, rest} ->
        Process.put(:freeq_batches, rest)
        assembled = Freeq.Batch.assemble(Enum.reverse(lines))
        [":" <> assembled | acc]

      {nil, _rest} ->
        acc
    end
  end

  defp handle_batch_line("@batch=" <> rest, acc) do
    batches = Process.get(:freeq_batches, %{})

    if map_size(batches) > 0 do
      [bid, msg] = String.split(rest, " ", parts: 2)
      bid = String.split(bid, ";") |> List.first()

      case Map.get(batches, bid) do
        {t, tgt, lines} ->
          body =
            case String.split(msg, " :", parts: 2) do
              [_prefix, b] -> b
              _ -> ""
            end

          new_batches = Map.put(batches, bid, {t, tgt, [body | lines]})
          Process.put(:freeq_batches, new_batches)
          acc

        nil ->
          [rest | acc]
      end
    else
      ["@batch=" <> rest | acc]
    end
  end

  defp handle_batch_line(line, acc) do
    [line | acc]
  end

  def reply(agent) do
    name = to_string(agent)
    await("reply from #{name}", &from(&1, name)) |> text()
  end

  def said?(from, to, fragment) do
    transcript = Process.get(:freeq_transcript, [])
    Enum.any?(transcript, &matches?(&1, from, to, fragment))
  end

  def wait_said?(from, to, fragment) do
    await("#{from} tells #{to}: #{fragment}", &matches?(&1, from, to, fragment))
  end

  defp matches?(line, from, to, fragment) do
    String.starts_with?(line, ":#{from}!") and
      String.contains?(line, "PRIVMSG #the-lab :") and
      addressee_match(line, to, fragment)
  end

  defp addressee_match(line, to, fragment) do
    case String.split(line, "PRIVMSG #the-lab :", parts: 2) do
      [_, message] -> starts_with?(message, to) and includes?(message, fragment)
      _ -> false
    end
  end

  defp starts_with?(message, to), do: String.starts_with?(message, "#{to}: ")

  defp includes?(message, fragment),
    do: String.contains?(String.downcase(message), String.downcase(fragment))

  defp from(line, agent),
    do: String.starts_with?(line, ":#{agent}!") and String.contains?(line, "PRIVMSG")

  defp text(line), do: line |> String.split(" :", parts: 2) |> List.last()
end
