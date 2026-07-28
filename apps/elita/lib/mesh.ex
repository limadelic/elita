defmodule Elita.Mesh do
  import Module, only: [concat: 2]
  import Logger, only: [info: 1]

  def start_link(nil) do
    info("Joining mesh via dial")
    apply(concat(El.Distribution, Helpers), :dial, [])
    :ignore
  end
end
