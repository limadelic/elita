defmodule Freeq.Batch do
  def feed(nil, line), do: feed_idle(line)
  def feed({:batch, ref, lines}, line), do: feed_batch(ref, lines, line)

  defp feed_idle(line) do
    if String.contains?(line, "BATCH +"),
      do: {:pending, {:batch, extract_ref(line), []}},
      else: {:message, line, nil}
  end

  defp feed_batch(ref, lines, line) do
    if String.contains?(line, "BATCH -" <> ref),
      do: {:message, assemble(Enum.reverse(lines)), nil},
      else: {:pending, {:batch, ref, [line | lines]}}
  end

  defp extract_ref(line) do
    match = Regex.run(~r/BATCH \+(\S+)/, line)
    if match && Enum.at(match, 1), do: Enum.at(match, 1), else: nil
  end

  defp assemble([first | rest]),
    do: assemble_with(parse_msg(first), rest)

  defp assemble_with({src, chan, txt}, rest) do
    rest_txt = rest |> Enum.map(&parse_msg/1) |> Enum.map(&elem(&1, 2))
    "#{src} PRIVMSG #{chan} :#{Enum.join([txt | rest_txt], "\n")}"
  end

  defp parse_msg(line) do
    [pfx, chan_txt] = String.split(line, " PRIVMSG ", parts: 2)
    src = Regex.run(~r/:[\w!@.]+/, pfx) |> List.first()
    [chan, txt] = String.split(chan_txt, " ", parts: 2)
    {src, chan, String.trim_leading(txt, ":")}
  end
end
