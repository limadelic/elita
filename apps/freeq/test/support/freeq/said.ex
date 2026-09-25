defmodule Freeq.Said do
  def said?(from, to, fragment) do
    Process.get(:freeq_transcript, []) |> Enum.any?(&matches?(&1, from, to, fragment))
  end

  def matches?(line, from, to, fragment) do
    String.starts_with?(line, ":#{from}!") and
      String.contains?(line, "PRIVMSG #the-lab :") and
      addressee(line, to, fragment)
  end

  defp addressee(line, to, fragment) do
    line |> String.split("PRIVMSG #the-lab :", parts: 2) |> body(to, fragment)
  end

  defp body([_, message], to, fragment) do
    String.starts_with?(message, "#{to}: ") and includes?(message, fragment)
  end

  defp body(_split, _to, _fragment), do: false

  defp includes?(message, fragment),
    do: String.contains?(String.downcase(message), String.downcase(fragment))
end
