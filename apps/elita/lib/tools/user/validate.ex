defmodule Tools.User.Validate do
  import String, only: [split: 2, trim: 1]
  import Enum, only: [map: 2, reduce: 3, find: 2, member?: 2]
  import Code, only: [string_to_quoted: 1]
  import Macro, only: [prewalk: 3]

  def check(tool) do
    tool[:code]
    |> process(tool[:params], tool[:name])
    |> unwrap(tool)
  end

  defp process([], _, _), do: :ok
  defp process(nil, _, _), do: :ok
  defp process(_, nil, _), do: :ok
  defp process(_, "", _), do: :ok

  defp process(code, params, name) do
    allowed = split(params, ",") |> map(&trim/1)
    reduce(code, :ok, &fold(&1, allowed, name, &2))
  end

  defp fold(_code, _allowed, _name, {:error, _} = err), do: err

  defp fold(code, allowed, name, :ok) do
    code |> string_to_quoted() |> scan(allowed, name)
  end

  defp scan({:ok, ast}, allowed, name), do: vet(ast, allowed, name)
  defp scan({:error, _}, _, _), do: :ok

  defp vet(ast, allowed, name) do
    bad_var = find(refs(ast), &bad?(&1, allowed, bound(ast)))
    handle_result(bad_var, name)
  end

  defp bad?(var, allowed, bound) do
    [allowed, bound] |> Enum.all?(&skip?(&1, var))
  end

  defp skip?(list, var), do: not member?(list, var)

  defp handle_result(nil, _), do: :ok
  defp handle_result(undefined, name), do: {:error, name, undefined}

  defp bound(ast) do
    {_ast, bound} = prewalk(ast, [], &bind/2)
    bound
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

  defp refs(ast) do
    {_ast, refs} = prewalk(ast, [], &mark/2)
    refs
  end

  defp mark({nil, _meta, nil}, refs), do: {nil, refs}
  defp mark({true, _meta, nil}, refs), do: {true, refs}
  defp mark({false, _meta, nil}, refs), do: {false, refs}

  defp mark({name, _meta, nil}, refs) when is_atom(name) do
    {nil, [Atom.to_string(name) | refs]}
  end

  defp mark(node, refs), do: {node, refs}

  defp unwrap(:ok, tool), do: tool

  defp unwrap({:error, name, var}, _tool) do
    raise RuntimeError, "#{name} undefined variable #{var}"
  end
end
