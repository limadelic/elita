defmodule Elita.Credo.Aliases do
  use Credo.Check, category: :refactor, base_priority: :normal

  import Credo.Code

  @msg "Use import instead of alias to bring functions into scope."
  @check_desc "Do not use alias directives. Import module functions instead."

  def explanations do
    [check: @check_desc]
  end

  def run(%Credo.SourceFile{} = source_file, _params) do
    filename = source_file.filename
    prewalk(source_file, &flag(&1, &2, filename))
  end

  defp flag({:alias, meta, _args} = ast, issues, filename) do
    {ast, [issue(meta, filename) | issues]}
  end

  defp flag(ast, issues, _filename) do
    {ast, issues}
  end

  defp issue(meta, filename) do
    %Credo.Issue{category: :refactor, exit_status: 2, check: __MODULE__,
                 message: @msg, line_no: meta[:line], column: meta[:column],
                 priority: :normal, filename: filename}
  end
end
