defmodule SseTest do
  use ExUnit.Case

  import Jason, only: [encode!: 1]

  test "invalid JSON in data line sets err" do
    s = Sse.init(emit: nil, ink: :none, name: nil)
    s = Sse.feed("data: not-json\n", s)
    assert s.err == "invalid JSON in SSE data line"
  end

  test "invalid JSON does not replace prior err" do
    s = Sse.init(emit: nil, ink: :none, name: nil)
    s = %{s | err: "upstream"}
    s = Sse.feed("data: not-json\n", s)
    assert s.err == "upstream"
  end

  test "assembles text block from deltas" do
    s = Sse.init(emit: nil, ink: :none, name: nil)

    start_ev = %{
      "type" => "content_block_start",
      "index" => 0,
      "content_block" => %{"type" => "text"}
    }

    delta_ev = %{
      "type" => "content_block_delta",
      "index" => 0,
      "delta" => %{"type" => "text_delta", "text" => "hello"}
    }

    s =
      s
      |> feed_line("data: #{encode!(start_ev)}")
      |> feed_line("data: #{encode!(delta_ev)}")

    s = Sse.finalize(s)
    assert s.err == nil

    assert [%{"type" => "text", "text" => "hello"}] = Sse.content(s)
  end

  defp feed_line(s, line), do: Sse.feed(line <> "\n", s)
end
