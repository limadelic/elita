defmodule Elita.Freeq.Parser do
  import String,
    only: [
      split: 3,
      starts_with?: 2,
      trim_leading: 1,
      trim_leading: 2,
      trim: 1
    ]

  import List, only: [first: 1]
  import Enum, only: [any?: 2]

  def parse(msg, nick, channel) do
    msg |> split(" PRIVMSG ", parts: 2) |> find(nick, channel)
  end

  defp find([sender_part, rest], nick, channel) do
    name = sender_part |> trim_leading() |> split("!", parts: 2) |> first()
    rest |> split(" :", parts: 2) |> route(nick, channel, name)
  end

  defp find(_, _nick, _channel), do: :noop

  defp route([target, text], nick, channel, sender) do
    said(target == channel, target == nick, sender, text, nick)
  end

  defp route(_, _nick, _channel, _sender), do: :noop

  defp said(true, _false, sender, text, nick) do
    result(cite(text, nick), sender, text, nick)
  end

  defp said(_true, true, sender, text, _nick) do
    {:ask, sender, text}
  end

  defp said(_true, _false, _sender, _text, _nick) do
    :noop
  end

  defp result(true, sender, text, nick) do
    {:ask, sender, clean(text, nick)}
  end

  defp result(false, _sender, _text, _nick) do
    :noop
  end

  defp cite(text, nick) do
    prefixes = ["#{nick}:", "#{nick},", "#{nick} ", "@#{nick}:", "@#{nick},", "@#{nick} "]
    any?(prefixes, &starts_with?(text, &1))
  end

  defp clean(text, nick) do
    text |> trim_leading("@") |> cut(nick) |> trim()
  end

  defp cut(text, nick) do
    trim_leading(text, "#{nick}:") |> trim_leading("#{nick},")
  end
end
