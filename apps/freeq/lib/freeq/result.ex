defmodule Freeq.Result do
  import String, only: [split: 3, contains?: 2, trim_trailing: 2]
  import List, only: [wrap: 1]

  def result?("@" <> rest) do
    rest |> split(" ", parts: 2) |> hd() |> contains?("+elita/result")
  end

  def result?(_line), do: false

  def clean(line), do: line |> to_string() |> trim_trailing("\r\n") |> wrap()
end
