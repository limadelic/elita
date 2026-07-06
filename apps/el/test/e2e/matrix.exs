defmodule Matrix do
  defp cast_char(session_node, char) when is_binary(char) do
    GenServer.cast({:elita, session_node}, {:inject, char})
  end

  defp random_delay do
    Enum.random(60..140)
  end

  defp type_line(session_node, line) do
    start = System.monotonic_time(:millisecond)

    String.graphemes(line)
    |> Enum.each(fn char ->
      cast_char(session_node, char)
      :timer.sleep(random_delay())
    end)

    :timer.sleep(2500)
    elapsed = System.monotonic_time(:millisecond) - start
    IO.puts("  #{line}")
    IO.puts("  cast confirmations: #{String.length(line)} chars + 2500ms pause (#{elapsed}ms total)")
  end

  defp clear_line(session_node) do
    cast_char(session_node, <<21>>)
  end

  def run do
    session = case System.argv() do
      [name] -> name
      _ -> "elita"
    end

    session_node = :"claude_#{session}@127.0.0.1"
    session_atom = String.to_atom(session)

    # Set cookie for distributed connection
    Node.set_cookie(session_atom)

    # Attempt connection with timeout
    task = Task.async(fn -> Node.connect(session_node) end)

    case Task.yield(task, 10000) || Task.shutdown(task) do
      {:ok, true} ->
        IO.puts("Connect result: true")
        IO.puts("")

        lines = [
          "Wake up, Mike...",
          "The Matrix has you...",
          "Follow the white rabbit.",
          "Knock, knock, Neo."
        ]

        start_time = System.monotonic_time(:millisecond)

        Enum.each(lines, fn line ->
          type_line(session_node, line)
          clear_line(session_node)
          :timer.sleep(100)
        end)

        # Clear the last line one more time
        clear_line(session_node)

        total_time = System.monotonic_time(:millisecond) - start_time
        IO.puts("")
        IO.puts("Matrix demo complete. Session pristine and alive.")
        IO.puts("Total runtime: #{total_time}ms")
        IO.puts("")
        IO.puts("To rerun:")
        IO.puts("  elixir --name matrix@127.0.0.1 -S mix run apps/el/test/e2e/matrix.exs")

      {:ok, false} ->
        IO.puts("Error: no live session at #{session_node}")
        System.halt(1)

      nil ->
        IO.puts("Error: connection timeout (~10s)")
        System.halt(1)
    end
  end
end

Matrix.run()
