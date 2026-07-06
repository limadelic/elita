import ExUnit.CaptureIO

output = capture_io(fn ->
  IO.puts("DEBUG: Starting test")
  El.CLI.main(["ls"])
  IO.puts("DEBUG: After main")
end)

IO.puts("========== CAPTURED OUTPUT (hex) ==========")
IO.inspect(output)
IO.puts("========== CAPTURED OUTPUT (text) ==========")
IO.write(output)
