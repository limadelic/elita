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
    reduce(code_list, :ok, &check_snippet(&1, allowed, name, &2))
  end

  defp check_snippet(_code, _allowed, _name, {:error, _} = err), do: err

  defp check_snippet(code, allowed, name, :ok) do
    analyze(code, allowed, name)
  end

  defp analyze(code, allowed, name) do
    case string_to_quoted(code) do
      {:ok, ast} -> check_vars(ast, allowed, name)
      {:error, _} -> :ok
    end
  end

  defp check_vars(ast, allowed, name) do
    bound = collect_bound(ast)
    refs = collect_refs(ast)
    undefined = find(refs, &is_undefined?(&1, allowed, bound))

    if undefined, do: {:error, name, undefined}, else: :ok
  end

  defp is_undefined?(var, allowed, bound) do
    not member?(allowed, var) and not member?(bound, var)
  end

  defp collect_bound(ast) do
    {_ast, bound} = prewalk(ast, [], &track_bound/2)
    bound
  end

  defp track_bound({:=, _meta, [pattern, _expr]}, bound) do
    {nil, extract_names(pattern, bound)}
  end

  defp track_bound(node, bound) do
    {node, bound}
  end

  defp extract_names({name, _, nil}, acc)
       when is_atom(name) and name not in [:_, nil, true, false] do
    [Atom.to_string(name) | acc]
  end

  defp extract_names({:_, _, nil}, acc), do: acc

  defp extract_names({_name, _, args}, acc) when is_list(args) do
    reduce(args, acc, &extract_names/2)
  end

  defp extract_names({left, right}, acc) do
    extract_names(left, extract_names(right, acc))
  end

  defp extract_names(list, acc) when is_list(list) do
    reduce(list, acc, &extract_names/2)
  end

  defp extract_names(_node, acc), do: acc

  defp collect_refs(ast) do
    {_ast, refs} = prewalk(ast, [], &track_refs/2)
    refs
  end

  defp track_refs({name, _meta, nil}, refs)
       when is_atom(name) and name not in [nil, true, false] do
    {nil, [Atom.to_string(name) | refs]}
  end

  defp track_refs(node, refs) do
    {node, refs}
  end

  defp unwrap(:ok, tool), do: tool

  defp unwrap({:error, name, var}, _tool) do
    raise RuntimeError, "#{name} undefined variable #{var}"
  end
end
