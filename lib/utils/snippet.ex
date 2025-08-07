defmodule Snippet do
  import Regex, only: [replace: 3]
  import Enum, only: [map: 2, join: 2]
  import Code, only: [eval_string: 1]
  import List, only: [wrap: 1]

  @snippet ~r/(?<!`)`([^`\n]+)`(?!`)/

  def snip(md, imports \\ []) do
    imports = build(imports)
    replace(@snippet, md, fn _, code ->
      eval(imports, code)
    end)
  end

  defp eval(imports, code) do
    {result, _} = eval_string("#{imports}; #{code}")
    to_string(result)
  rescue
    _ -> code
  end

  defp build(imports) do
    wrap(imports) |> map(&"import #{&1}") |> join("; ")
  end
end
