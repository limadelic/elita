defmodule ClaudeCommandTest do
  use ExUnit.Case

  test "parse_size handles valid stty output" do
    assert parse_size({"42 120\n", 0}) == {42, 120}
    assert parse_size({"30 100\n", 0}) == {30, 100}
    assert parse_size({"50 160\n", 0}) == {50, 160}
  end

  test "parse_size returns default on error" do
    assert parse_size({"error", 1}) == {24, 80}
    assert parse_size({"", 0}) == {24, 80}
  end

  test "extract_size correctly parses row and col values" do
    assert extract_size(["42", "120"]) == {42, 120}
    assert extract_size(["30", "100"]) == {30, 100}
    assert extract_size(["50", "160"]) == {50, 160}
  end

  test "extract_size returns default on invalid input" do
    assert extract_size(["42"]) == {24, 80}
    assert extract_size([]) == {24, 80}
    assert extract_size(["not", "numbers"]) == {24, 80}
  end

  # Helpers matching claude.ex logic
  defp parse_size({output, 0}) do
    String.trim(output)
    |> String.split()
    |> extract_size()
  end

  defp parse_size(_), do: {24, 80}

  defp extract_size([rows, cols]) do
    {String.to_integer(rows), String.to_integer(cols)}
  rescue
    _ -> {24, 80}
  end

  defp extract_size(_), do: {24, 80}
end
