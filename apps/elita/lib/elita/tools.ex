defmodule Elita.Tools do
  alias Elita.{Convo, Parser, Executor}
  import Enum, only: [join: 2, reduce: 3, reverse: 1]

  def process({:ok, reply}, state) do
    dispatch(Parser.has_tools?(reply), reply, state)
  end

  def process(error, state), do: {:error, error, state}

  defp dispatch(true, reply, state) do
    {results, state} = execute(reply, state)
    {:continue, %{state | convo: Convo.msg(state.convo, %{role: "tool", content: join(results, "; ")})}}
  end

  defp dispatch(false, reply, state) do
    {:done, reply, state}
  end

  defp execute(reply, state) do
    {results, state} = 
      reply
      |> Parser.extract()
      |> reduce({[], state}, fn tool, {results, state} ->
        {result, state} = Executor.call(tool, state)
        {[result | results], state}
      end)
    
    {reverse(results), state}
  end
end