import ExUnit.CaptureIO

output = capture_io(fn ->
  IO.inspect(Node.self(), label: "Node.self() before Distribution")
  El.Distribution.start()
  IO.inspect(Node.self(), label: "Node.self() after Distribution")
end)

IO.puts("Output:")
IO.write(output)
