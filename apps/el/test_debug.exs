import ExUnit.CaptureIO

output = capture_io(fn ->
  El.CLI.main(["ls"])
end)

IO.puts("========== CAPTURED OUTPUT ==========")
IO.inspect(output)
IO.puts("Length: #{byte_size(output)}")
IO.puts("Contains 'sessions': #{String.contains?(output, "sessions")}")
IO.puts("Contains 'claude_': #{String.contains?(output, "claude_")}")
