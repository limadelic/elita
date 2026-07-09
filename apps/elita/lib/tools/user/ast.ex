defmodule Tools.User.Ast do
  import Enum, only: [reduce: 3]
  import Macro, only: [prewalk: 3]

  def bound(ast) do
    {_ast, bound} = prewalk(ast, [], &bind/2)
    bound
  end

  def refs(ast) do
    {_ast, refs} = prewalk(ast, [], &mark/2)
    refs
  end

  defp bind({:=, _meta, [pattern, _expr]}, bound) do
    {nil, names(pattern, bound)}
  end

  defp bind(node, bound) do
    {node, bound}
  end

  defp names({:_, _, nil}, acc), do: acc
  defp names({nil, _, nil}, acc), do: acc
  defp names({true, _, nil}, acc), do: acc
  defp names({false, _, nil}, acc), do: acc

  defp names({name, _, nil}, acc) when is_atom(name) do
    [Atom.to_string(name) | acc]
  end

  defp names({_name, _, args}, acc) when is_list(args) do
    reduce(args, acc, &names/2)
  end

  defp names({left, right}, acc) do
    names(left, names(right, acc))
  end

  defp names(list, acc) when is_list(list) do
    reduce(list, acc, &names/2)
  end

  defp names(_node, acc), do: acc

  defp mark({nil, _meta, nil}, refs), do: {nil, refs}
  defp mark({true, _meta, nil}, refs), do: {true, refs}
  defp mark({false, _meta, nil}, refs), do: {false, refs}

  defp mark({name, _meta, nil}, refs) when is_atom(name) do
    {nil, [to_string(name) | refs]}
  end

  defp mark(node, refs), do: {node, refs}
end
