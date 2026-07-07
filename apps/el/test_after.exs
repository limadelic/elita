import ExUnit.CaptureIO

output = capture_io(fn ->
  El.CLI.main(["ls"])
end)

IO.puts("Output:")
IO.inspect(output)
