defmodule Tools.User.Validate do
  import String, only: [split: 2, trim: 1]
  import Enum, only: [map: 2]
  import Code, only: [eval_string: 2]

  def check(tool) do
    tool
    |> validate()
    |> unwrap(tool)
  end

  defp validate(tool) do
    validate_params(tool[:code], tool[:params], tool[:name])
  end

  defp validate_params([], _, _), do: :ok
  defp validate_params(nil, _, _), do: :ok
  defp validate_params(_, nil, _), do: :ok
  defp validate_params(_, "", _), do: :ok
  defp validate_params(code, params, name), do: scan(code, params, name)

  defp scan(code, params, name) do
    allowed = split(params, ",") |> map(&trim/1)
    check_code(code, allowed, name)
  end

  defp check_code(code_list, allowed, name) do
    code_list
    |> Enum.reduce(:ok, &check_snippet(&1, allowed, name, &2))
  end

  defp check_snippet(code, _allowed, _name, {:error, _} = err), do: err

  defp check_snippet(code, allowed, name, :ok) do
    attempt(code, allowed, name)
  end

  defp attempt(code, allowed, name) do
    bindings = map(allowed, &{String.to_atom(&1), nil})
    {:ok, eval_string(code, bindings)}
  rescue
    error -> handle_error(error, code, allowed, name)
  end

  defp handle_error(%CompileError{}, code, allowed, name) do
    {:error, name, find_undefined(code, allowed)}
  end

  defp handle_error(_error, _code, _allowed, _name), do: :ok

  defp find_undefined(code, allowed) do
    case Code.string_to_quoted(code) do
      {:ok, ast} -> find_var_not_allowed(ast, allowed)
      {:error, _} -> ""
    end
  end

  defp find_var_not_allowed(ast, allowed) do
    vars = collect_vars(ast, [])
    Enum.find(vars, fn var -> not Enum.member?(allowed, var) end) || ""
  end

  defp collect_vars({name, _, nil}, acc) when is_atom(name) do
    [Atom.to_string(name) | acc]
  end

  defp collect_vars({_name, _meta, args}, acc) when is_list(args) do
    Enum.reduce(args, acc, &collect_vars/2)
  end

  defp collect_vars({left, right}, acc) do
    collect_vars(left, collect_vars(right, acc))
  end

  defp collect_vars(_node, acc), do: acc

  defp unwrap(:ok, tool), do: tool

  defp unwrap({:error, name, var}, _tool) do
    raise RuntimeError, "#{name} undefined variable #{var}"
  end
end
