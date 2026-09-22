defmodule Elita.Freeq.Parser do
  import String, only: [split: 3, starts_with?: 2, trim_leading: 1, trim_leading: 2]

  def parse(msg, nick, channel) do
    msg |> split(" PRIVMSG ", parts: 2) |> match(nick, channel)
  end

  defp match([sender_part, rest], nick, channel) do
    sender = sender_part |> trim_leading() |> String.split("!") |> List.first()
    rest |> split(" :", parts: 2) |> ask(nick, channel, sender)
  end

  defp match(_, _nick, _channel), do: :noop

  defp ask([target, text], nick, channel, sender) do
    cond do
      target == channel and mention?(text, nick) -> {:ask, sender, strip(text, nick)}
      target == nick -> {:ask, sender, text}
      true -> :noop
    end
  end

  defp ask(_, _nick, _channel, _sender), do: :noop

  defp mention?(text, nick) do
    starts_with?(text, "#{nick}:") or
      starts_with?(text, "#{nick},") or
      starts_with?(text, "@#{nick}") or
      Regex.match?(~r/^@?#{Regex.escape(nick)}[,:\s]/, text)
  end

  defp strip(text, nick) do
    text
    |> trim_leading("@")
    |> trim_leading("#{nick}:")
    |> trim_leading("#{nick},")
    |> String.trim()
  end
end
