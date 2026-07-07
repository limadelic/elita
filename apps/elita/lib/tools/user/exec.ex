defmodule Tools.User.Exec do
  import Code, only: [eval_string: 2]
  import Enum, only: [map: 2, join: 2, at: 2]
  import Log, only: [log: 5]
  import String, only: [split: 2, trim: 1]

  def exec(tool, args) when tool != nil do
    log("🛠️", tool.name, ": ", args, :red)
    result = first(tool.code, tool, args)
    log("", "", "", result, :yellow)
    result
  end

  def exec(nil, _args), do: {:error, "Tool not found"}

  defp first([], _, _), do: "No code found"

  defp first([code | _], tool, args) do
    tool.imports
    |> modules()
    |> imports()
    |> plus(code)
    |> eval(args, tool.name)
  end

  defp modules(nil), do: []
  defp modules(""), do: []
  defp modules(text), do: split(text, ",") |> map(&trim/1)

  defp imports(modules) when is_list(modules) do
    ["import Tool.Index"] ++ map(modules, &imports/1)
  end

  defp imports(module), do: "import #{module}"

  defp plus(imports, code) do
    """
    #{join(imports, "\n")}

    #{code}
    """
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
    bindings = args |> Map.to_list() |> map(&atomize_key/1)
    result(eval_string(text, bindings))
  end

  defp atomize_key({k, v}) when is_binary(k), do: {String.to_atom(k), v}
  defp atomize_key({k, v}), do: {k, v}

  defp result({res, _}), do: res

  defp failed(%CompileError{description: desc}, _, name),
    do: "#{name} needs #{var(desc)}"

  defp failed(error, stack, _), do: reraise(error, stack)

  defp var(desc) do
    at(split(desc, "\""), 1)
  end
end
