defmodule Cache do
  import Map, only: [put: 3]
  import List, only: [pop_at: 2]

  @cache_key %{type: "ephemeral"}

  def sys([%{type: "text"} = m | rest]),
    do: [put(m, :cache_control, @cache_key) | rest]

  def sys(other), do: other

  def tools([]), do: []

  def tools(list) do
    {last, init} = pop_at(list, -1)
    init ++ [put(last, :cache_control, @cache_key)]
  end

  def messages([]), do: []

  def messages(list) do
    {last, init} = pop_at(list, -1)
    init ++ [wrap(last)]
  end

  defp wrap(%{content: str} = m) when is_binary(str),
    do: put(m, :content, [%{type: "text", text: str, cache_control: @cache_key}])

  defp wrap(%{content: blocks} = m) when is_list(blocks) do
    {block, rest} = pop_at(blocks, -1)
    put(m, :content, rest ++ [put(block, :cache_control, @cache_key)])
  end

  defp wrap(msg), do: msg
end
