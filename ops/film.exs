#!/usr/bin/env elixir
# Film a single claude command via Matrix.Pty recording

if System.get_env("TAPE") != "rec" do
  IO.puts("rec mode required")
  System.halt(0)
end

System.put_env("CASSETTE_DIR", Path.expand("../features/cassettes", __DIR__))
System.put_env("CASSETTE", "claude")

app_dir = Path.expand("..", __DIR__)

# Load apps
[
  "apps/matrix/lib",
  "apps/tape/lib",
  "apps/elita/lib"
]
|> Enum.each(&Code.compile_file("#{app_dir}/#{&1}"))

Code.load_paths([
  "#{app_dir}/apps/matrix/lib",
  "#{app_dir}/apps/tape/lib",
  "#{app_dir}/apps/elita/lib"
])

# Start minimal supervision tree
{:ok, _} = Supervisor.start_link([], strategy: :one_for_one)

# Boot and run the pty
try do
  pid = Matrix.Pty.launch(
    :film,
    cmd: "claude --model haiku -p \"reply with exactly: action!\""
  )

  result = receive do
    {:DOWN, _ref, :process, ^pid, _reason} -> :ok
  after
    60_000 -> {:error, :timeout}
  end

  case result do
    :ok -> System.halt(0)
    {:error, :timeout} -> System.halt(1)
  end
rescue
  e ->
    IO.puts("Error: #{inspect(e)}")
    System.halt(1)
end
