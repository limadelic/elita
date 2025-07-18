defmodule Elita.Tools do
  alias Elita.Convo
  import String, only: [contains?: 2, split: 2, split: 3, trim: 1]
  import Enum, only: [join: 2, reduce: 3, drop: 2, map: 2, filter: 2, reverse: 1, into: 2]

  def process({:ok, reply}, state) do
    dispatch(has_tools?(reply), reply, state)
  end

  def process(error, state), do: {:error, error, state}

  defp dispatch(true, reply, state) do
    {results, state} = execute(reply, state)
    {:continue, %{state | convo: Convo.msg(state.convo, %{role: "tool", content: join(results, "; ")})}}
  end

  defp dispatch(false, reply, state) do
    {:done, reply, state}
  end

  defp has_tools?(reply) do
    contains?(reply, "<function_calls>")
  end

  defp execute(reply, state) do
    {results, state} = 
      reply
      |> extract()
      |> reduce({[], state}, fn tool, {results, state} ->
        {result, state} = call(tool, state)
        {[result | results], state}
      end)
    
    {reverse(results), state}
  end

  defp extract(reply) do
    reply
    |> split("<invoke name=\"")
    |> drop(1)
    |> map(&parse/1)
    |> filter(& &1)
  end

  defp parse(block) do
    with [name | rest] <- split(block, "\">", parts: 2),
         [params | _] <- rest,
         parameters <- params(params) do
      {name, parameters}
    else
      _ -> nil
    end
  end

  defp params(params) do
    params
    |> split("<parameter name=\"")
    |> drop(1)
    |> map(&param/1)
    |> into(%{})
  end

  defp param(block) do
    with [name | rest] <- split(block, "\">", parts: 2),
         [value | _] <- rest,
         [value | _] <- split(value, "</parameter>") do
      {name, trim(value)}
    else
      _ -> {"", ""}
    end
  end

  defp call({"set", %{"field" => field, "value" => value}}, state) do
    {"stored #{field}", %{state | memory: Map.put(state.memory, field, value)}}
  end

  defp call({"say", %{"message" => message}}, state) do
    {"broadcasted: #{message}", state}
  end

  defp call({name, _params}, state) do
    {"unknown tool: #{name}", state}
  end
end