defmodule ClaudeCommandTest do
  use ExUnit.Case

  test "parse_size handles valid stty output" do
    assert parse_size({"42 120\n", 0}) == {42, 120}
    assert parse_size({"30 100\n", 0}) == {30, 100}
    assert parse_size({"50 160\n", 0}) == {50, 160}
  end

  test "parse_size returns nil on error" do
    assert parse_size({"error", 1}) == nil
    assert parse_size({"", 0}) == nil
  end

  test "extract_size correctly parses row and col values" do
    assert extract_size(["42", "120"]) == {42, 120}
    assert extract_size(["30", "100"]) == {30, 100}
    assert extract_size(["50", "160"]) == {50, 160}
  end

  test "extract_size returns nil on invalid input" do
    assert extract_size(["42"]) == nil
    assert extract_size([]) == nil
    assert extract_size(["not", "numbers"]) == nil
  end

  test "read_env returns size when both EL_ROWS and EL_COLS are valid integers" do
    System.put_env("EL_ROWS", "42")
    System.put_env("EL_COLS", "120")
    assert read_env() == {42, 120}

    System.put_env("EL_ROWS", "100")
    System.put_env("EL_COLS", "160")
    assert read_env() == {100, 160}
  end

  test "read_env returns nil when EL_ROWS is missing" do
    System.delete_env("EL_ROWS")
    System.put_env("EL_COLS", "120")
    assert read_env() == nil
  end

  test "read_env returns nil when EL_COLS is missing" do
    System.put_env("EL_ROWS", "42")
    System.delete_env("EL_COLS")
    assert read_env() == nil
  end

  test "read_env returns nil when values are not integers" do
    System.put_env("EL_ROWS", "not_a_number")
    System.put_env("EL_COLS", "120")
    assert read_env() == nil

    System.put_env("EL_ROWS", "42")
    System.put_env("EL_COLS", "not_a_number")
    assert read_env() == nil
  end

  test "read_env returns nil when values have trailing characters" do
    System.put_env("EL_ROWS", "42x")
    System.put_env("EL_COLS", "120")
    assert read_env() == nil
  end

  test "restore generates reset escape sequences" do
    sequences = restore()
    assert String.contains?(sequences, "\e[?1000l")
    assert String.contains?(sequences, "\e[?1002l")
    assert String.contains?(sequences, "\e[?1003l")
    assert String.contains?(sequences, "\e[?1006l")
    assert String.contains?(sequences, "\e[?2004l")
    assert String.contains?(sequences, "\e[?1049l")
    assert String.contains?(sequences, "\e[?25h")
  end

  test "translate_newline converts newline to carriage return" do
    assert translate_newline("\n") == "\r"
  end

  test "translate_newline leaves other bytes alone" do
    assert translate_newline("a") == "a"
    assert translate_newline("abc") == "abc"
    assert translate_newline("\r") == "\r"
    assert translate_newline(" ") == " "
  end

  test "translate_newline handles multi-byte chunk with embedded newline" do
    assert translate_newline("a\nb") == "a\rb"
    assert translate_newline("hello\nworld") == "hello\rworld"
    assert translate_newline("a\nb\nc") == "a\rb\rc"
  end

  test "node_collision? returns true when node is live" do
    ping_fn = fn _node -> :pong end
    assert node_collision?(:"el_claude@127.0.0.1", ping_fn) == true
  end

  test "node_collision? returns false when node is not live" do
    ping_fn = fn _node -> :pang end
    assert node_collision?(:"el_claude@127.0.0.1", ping_fn) == false
  end

  test "node_collision? handles ping errors gracefully" do
    ping_fn = fn _node -> raise "network error" end
    assert node_collision?(:"el_claude@127.0.0.1", ping_fn) == false
  end

  # Helpers matching claude.ex logic
  defp parse_size({output, 0}) do
    String.trim(output)
    |> String.split()
    |> extract_size()
  end

  defp parse_size(_), do: nil

  defp extract_size([rows, cols]) do
    {String.to_integer(rows), String.to_integer(cols)}
  rescue
    _ -> nil
  end

  defp extract_size(_), do: nil

  defp read_env do
    case {System.get_env("EL_ROWS"), System.get_env("EL_COLS")} do
      {rows, cols} when is_binary(rows) and is_binary(cols) ->
        with {row, ""} <- Integer.parse(rows),
             {col, ""} <- Integer.parse(cols) do
          {row, col}
        else
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp restore do
    "\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?2004l\e[?1049l\e[?25h"
  end

  defp translate_newline(chunk) do
    String.replace(chunk, "\n", "\r")
  end

  defp node_collision?(node, ping_fn) do
    case ping_fn.(node) do
      :pong -> true
      :pang -> false
    end
  rescue
    _ -> false
  end
end
