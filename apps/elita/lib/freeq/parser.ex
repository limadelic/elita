defmodule Elita.Freeq.Parser do
  import String, only: [split: 3, starts_with?: 2]

  def parse(msg, nick, channel) do
    msg |> split(" PRIVMSG ", parts: 2) |> match(nick, channel)
  end

  defp match([sender_part, rest], nick, channel) do
    name = sender_part |> String.trim_leading() |> String.split("!") |> List.first()
    rest |> split(" :", parts: 2) |> ask(nick, channel, name)
  end

  defp match(_, _nick, _channel), do: :noop

  defp ask([target, text], nick, channel, sender) do
    cond do
      target == channel && mention?(text, nick) ->
        {:ask, sender, trim(text, nick)}

      target == nick ->
        {:ask, sender, text}

      true ->
        :noop
    end
  end

  defp ask(_, _nick, _channel, _sender), do: :noop

  defp mention?(text, nick) do
    starts_with?(text, "#{nick}:") || starts_with?(text, "#{nick},") ||
      starts_with?(text, "@#{nick}") ||
      Regex.match?(~r/^@?#{Regex.escape(nick)}[,:\s]/, text)
  end

  defp trim(text, nick) do
    text
    |> String.trim_leading("@")
    |> String.trim_leading("#{nick}:")
    |> String.trim_leading("#{nick},")
    |> String.trim()
  end
end
