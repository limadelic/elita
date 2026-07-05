defmodule Tools.User.Exec do
  import String, only: [split: 2, trim: 1]
  import Enum, only: [map: 2, join: 2]
  import Code, only: [eval_string: 2]
  import Log, only: [log: 5]

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
    |> modules
    |> imports
    |> plus(code)
    |> eval(args, tool.name)
  end

  defp modules(nil), do: []
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
    bindings = args |> Map.to_list()
    try do
      {result, _} = eval_string(text, bindings)
      result
    rescue
      error ->
        missing = extract_missing(error)
        "#{name} needs #{missing}"
    end
  end

  defp extract_missing(error) do
    message = Exception.message(error)
    case String.split(message, "undefined variable \"") do
      [_, rest] ->
        String.split(rest, "\"") |> List.first()
      _ ->
        "arg"
    end
  end
end
