defmodule Elita.Credo.Disables do
  use Credo.Check, category: :refactor, base_priority: :normal

  import File, only: [read!: 1]
  import String, only: [ends_with?: 2, contains?: 2, split: 2]
  import Enum, only: [with_index: 2, reduce: 3]
  import Map, only: [merge: 2]

  @msg "Do not use credo:disable suppressions"
  @desc "Credo disable directives are forbidden."
  @base %Credo.Issue{
    category: :refactor,
    exit_status: 2,
    message: @msg,
    priority: :normal,
    column: 1
  }

  def explanations do
    [check: @desc]
  end

  def run(%Credo.SourceFile{} = source_file, _params) do
    file = source_file.filename
    path(ends_with?(file, "disables.ex"), file)
  end

  defp path(true, _file), do: []
  defp path(false, file), do: read!(file) |> scan(file)

  defp scan(source, file) do
    source
    |> split("\n")
    |> with_index(1)
    |> reduce([], &line(&1, &2, file))
  end

  defp line({text, no}, issues, file) do
    bad(has?(text), no, issues, file)
  end

  defp bad(true, no, issues, file), do: [flag(no, file) | issues]
  defp bad(false, _no, issues, _file), do: issues

  defp has?(text), do: contains?(text, "credo:disable")

  defp flag(no, file) do
    @base |> merge(%{check: __MODULE__, line_no: no, filename: file})
  end
end
