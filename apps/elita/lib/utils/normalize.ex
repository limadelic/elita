defmodule Utils.Normalize do
  import String, only: [downcase: 1]

  def name(n) do
    n |> to_string() |> downcase()
  end
end
