defmodule InkTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  test "feed renders complete block to stderr" do
    out =
      capture_io(:stderr, fn ->
        s = Ink.new()
        Ink.feed(s, "# Title\n\n")
      end)

    assert out =~ "Title"
  end

  test "feed does not raise on odd input" do
    out =
      capture_io(:stderr, fn ->
        s = Ink.new()
        Ink.feed(s, "<<<not-md-but-ok>>>\n\n")
      end)

    assert is_binary(out)
  end
end
