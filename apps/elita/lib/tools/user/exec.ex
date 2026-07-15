defmodule Tools.User.Exec do
  import Code, only: [eval_string: 2]
  import Enum, only: [map: 2, join: 2, at: 2]
  import String, only: [split: 2, trim: 1, to_atom: 1]
  import Map, only: [to_list: 1]

  def exec(tool, args) when tool != nil do
    result = first(tool.code, tool, args)
    result
  end

  def exec(nil, _args), do: {:error, "Tool not found"}

  defp first([], _, _), do: "No code found"

  defp first([code | _], tool, args) do
    tool.imports |> modules() |> imports() |> plus(code) |> eval(args, tool.name)
  end

  defp modules(nil), do: []
  defp modules(""), do: []
  defp modules(text), do: split(text, ",") |> map(&trim/1)

  defp imports(modules) when is_list(modules) do
    ["import Tool.Index"] ++ map(modules, &imports/1)
  end

  defp imports(module), do: "import #{module}"

  defp plus(imports, code) do
    "\n#{join(imports, "\n")}\n\n#{code}\n"
  end

  defp eval(text, args, name) do
    attempt(text, args)
    |> result(name)
  end

  defp attempt(text, args) do
    {:ok, run(text, args)}
  rescue
    error -> {:error, error, __STACKTRACE__}
  end

  defp result({:ok, value}, _), do: value
  defp result({:error, error, stack}, name), do: failed(error, stack, name)

  defp run(text, args) do
    bindings = to_list(args) |> map(&atomize/1)
    result(eval_string(text, bindings))
  end

  defp atomize({k, v}) when is_binary(k), do: {to_atom(k), v}
  defp atomize({k, v}), do: {k, v}

  defp result({res, _}), do: res

  defp failed(%CompileError{description: desc}, _, name),
    do: "#{name} needs #{var(desc)}"

  defp failed(error, stack, _), do: reraise(error, stack)

  defp var(desc) do
    at(split(desc, "\""), 1)
  end
end
