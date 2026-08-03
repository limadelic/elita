#!/usr/bin/env elixir
# Film a door session - send all output together and wait

if System.get_env("TAPE") != "rec" do
  IO.puts("rec mode required")
  System.halt(0)
end

System.put_env("CASSETTE_DIR", Path.expand("../features/cassettes", __DIR__))
System.put_env("CASSETTE", "door")

Application.start(:logger)
Application.start(:matrix)
Application.start(:tape)
Application.start(:elita)

unique_name = "door_#{System.monotonic_time(:millisecond)}"
pty_name = String.to_atom(unique_name)

try do
  # Use printf to output everything as one unit, then wait
  pid = Matrix.Pty.launch(
    pty_name,
    cmd: "printf 'malko> 1 + 1\\n2\\nmalko> /exit\\n'; sleep 1"
  )

  receive do
    {:DOWN, _ref, :process, ^pid, _reason} -> System.halt(0)
  after
    30_000 -> System.halt(1)
  end
rescue
  _ -> System.halt(1)
end
