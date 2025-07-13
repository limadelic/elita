defmodule Elita.Agent do
  alias Elita.{Loader, Prompt, Pat}
  import Loader, only: [agent: 1]
  import Prompt, only: [prompt: 2]
  import Pat, only: [say: 1]

  def decide(name, context) do
    name
    |> agent()
    |> prompt(context)
    |> say()
  end
end