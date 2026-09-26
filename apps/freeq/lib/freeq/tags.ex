defmodule Freeq.Tags do
  import String, only: [split: 3, contains?: 2]
  import List, only: [last: 1]

  def result?("@" <> rest) do
    rest |> split(" ", parts: 2) |> hd() |> contains?("+elita/result")
  end

  def result?(_line), do: false

  def result, do: "@+elita/result "

  def strip("@" <> rest), do: rest |> split(" ", parts: 2) |> last()
  def strip(line), do: line
end
