defmodule Elita.Credo.AliasUsage do
  use Credo.Check, category: :refactor, base_priority: :normal

  alias Credo.SourceFile
  alias Credo.Code

  @check_desc "Do not use alias directives. Import module functions instead."

  def explanations do
    [check: @check_desc]
  end

  def run(%SourceFile{} = source_file, _params) do
    filename = source_file.filename
    Code.prewalk(source_file, &check_alias(&1, &2, filename))
  end

  defp check_alias({:alias, meta, _args} = ast, issues, filename) do
    {ast, [create_issue(meta, filename) | issues]}
  end

  defp check_alias(ast, issues, _filename) do
    {ast, issues}
  end

  defp create_issue(meta, filename) do
    msg = "Use import instead of alias to bring functions into scope."
    line = meta[:line]
    col = meta[:column]

    %Credo.Issue{
      category: :refactor,
      exit_status: 2,
      check: __MODULE__,
      message: msg,
      line_no: line,
      column: col,
      priority: :normal,
      filename: filename
    }
  end
end
