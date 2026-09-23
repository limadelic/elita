defmodule Freeq.Match do
  import String, only: [downcase: 1, contains?: 2, starts_with?: 2, split: 3]
  import Enum, only: [any?: 2, at: 2]

  def caps?(line), do: contains?(line, " 001 ")

  def join?(line), do: contains?(line, " 366 ")

  def connects(line, agent) do
    contains?(line, agent) and contains?(line, "JOIN")
  end

  def holds(line, fragment) do
    contains?(downcase(line), downcase(fragment))
  end

  def from_peer(line, agent) do
    has_nick?(line, agent) and contains?(line, "PRIVMSG")
  end

  defp has_nick?(line, agent) do
    starts_with?(line, ":#{agent}!") or contains?(line, ":#{agent}!")
  end

  def said?(from, to, fragment, transcript) do
    any?(transcript, &matches(&1, from, to, fragment))
  end

  defp matches(line, from, to, fragment) do
    starts_with?(line, ":#{from}!") and
      contains?(line, "PRIVMSG #the-lab :") and
      check_msg(line, to, fragment)
  end

  defp check_msg(line, to, fragment) do
    case split(line, "PRIVMSG #the-lab :", parts: 2) do
      [_, msg] -> starts_with?(msg, "#{to}: ") and contains?(downcase(msg), downcase(fragment))
      _ -> false
    end
  end

  def text(line) do
    line |> split(" :", parts: 2) |> at(1)
  end
end
