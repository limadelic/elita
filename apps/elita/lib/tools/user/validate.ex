defmodule Tools.User.Validate do
  import Code, only: [string_to_quoted: 1]
  import Enum, only: [map: 2, reduce: 3, find: 2, member?: 2, all?: 2]
  import String, only: [split: 2, trim: 1]
  import Tools.User.Ast, only: [bound: 1, refs: 1]

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
    bad = find(refs(ast), &bad?(&1, allowed, bound(ast)))
    resolve(bad, name)
  end

  defp bad?(var, allowed, bound) do
    [allowed, bound] |> all?(&skip?(&1, var))
  end

  defp skip?(list, var), do: not member?(list, var)

  defp resolve(nil, _), do: :ok
  defp resolve(undefined, name), do: {:error, name, undefined}

  defp unwrap(:ok, tool), do: tool

  defp unwrap({:error, name, var}, _tool) do
    raise RuntimeError, "#{name} undefined variable #{var}"
  end
end
