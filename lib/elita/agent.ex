defmodule Elita.Agent do
  alias Elita.{Loader, Prompt, Pat}
  
  defstruct [:name, :role, :goals, :instructions, :examples]

  def decide(name, context) do
    name
    |> Loader.agent()
    |> Prompt.build(context)
    |> Pat.say()
  end
end