defmodule Matrix do
  defp cast_char(char) when is_binary(char) do
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, char})
  end

  defp random_delay do
    Enum.random(60..140)
  end

  defp type_line(line) do
    start = System.monotonic_time(:millisecond)

    String.graphemes(line)
    |> Enum.each(fn char ->
      cast_char(char)
      :timer.sleep(random_delay())
    end)

    :timer.sleep(2500)
    elapsed = System.monotonic_time(:millisecond) - start
    IO.puts("  #{line}")
    IO.puts("  cast confirmations: #{String.length(line)} chars + 2500ms pause (#{elapsed}ms total)")
  end

  defp clear_line do
    cast_char(<<21>>)
  end

  def run do
    # Set cookie for distributed connection
    Node.set_cookie(:elita)

    # Attempt connection with timeout
    task = Task.async(fn -> Node.connect(:"el_claude@127.0.0.1") end)

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
          type_line(line)
          clear_line()
          :timer.sleep(100)
        end)

        # Clear the last line one more time
        clear_line()

        total_time = System.monotonic_time(:millisecond) - start_time
        IO.puts("")
        IO.puts("Matrix demo complete. Session pristine and alive.")
        IO.puts("Total runtime: #{total_time}ms")
        IO.puts("")
        IO.puts("To rerun:")
        IO.puts("  elixir --name matrix@127.0.0.1 -S mix run apps/el/e2e/matrix.exs")

      {:ok, false} ->
        IO.puts("Error: no live session at el_claude@127.0.0.1")
        System.halt(1)

      nil ->
        IO.puts("Error: connection timeout (~10s)")
        System.halt(1)
    end
  end
end

Matrix.run()
