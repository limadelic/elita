defmodule Tools.User.Validate do
  import String, only: [split: 2, trim: 1]
  import Enum, only: [map: 2, reduce: 3, find: 2, member?: 2]
  import Code, only: [string_to_quoted: 1]
  import Macro, only: [prewalk: 3]

  def check(tool) do
    tool
    |> validate()
    |> unwrap(tool)
  end

  defp validate(tool) do
    process(tool[:code], tool[:params], tool[:name])
  end

  defp process([], _, _), do: :ok
  defp process(nil, _, _), do: :ok
  defp process(_, nil, _), do: :ok
  defp process(_, "", _), do: :ok

  defp process(code, params, name) do
    allowed = split(params, ",") |> map(&trim/1)
    scan(code, allowed, name)
  end

  defp scan(code_list, allowed, name) do
    reduce(code_list, :ok, &fold(&1, allowed, name, &2))
  end

  defp fold(_code, _allowed, _name, {:error, _} = err), do: err

  defp fold(code, allowed, name, :ok) do
    analyze(code, allowed, name)
  end

  defp analyze(code, allowed, name) do
    case string_to_quoted(code) do
      {:ok, ast} -> vet(ast, allowed, name)
      {:error, _} -> :ok
    end
  end

  defp vet(ast, allowed, name) do
    bound = bound(ast)
    refs = refs(ast)
    undefined = find(refs, &loose?(&1, allowed, bound))

    if undefined, do: {:error, name, undefined}, else: :ok
  end

  defp loose?(var, allowed, bound) do
    not member?(allowed, var) and not member?(bound, var)
  end

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

  defp names({name, _, nil}, acc)
       when is_atom(name) and name not in [:_, nil, true, false] do
    [Atom.to_string(name) | acc]
  end

  defp names({:_, _, nil}, acc), do: acc

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

  defp mark({name, _meta, nil}, refs)
       when is_atom(name) and name not in [nil, true, false] do
    {nil, [Atom.to_string(name) | refs]}
  end

  defp mark(node, refs) do
    {node, refs}
  end

  defp unwrap(:ok, tool), do: tool

  defp unwrap({:error, name, var}, _tool) do
    raise RuntimeError, "#{name} undefined variable #{var}"
  end
end
