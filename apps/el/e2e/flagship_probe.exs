session = case System.argv() do
  [name] -> name
  _ -> "elita"
end

session_node = :"claude_#{session}@127.0.0.1"

case Node.connect(session_node) do
  true ->
    # Open model menu
    GenServer.cast({:elita, session_node}, {:inject, "/model\r"})
    :timer.sleep(1200)

    # Navigate to Haiku with raw escape sequences - 4 down arrows with 200ms gaps
    GenServer.cast({:elita, session_node}, {:inject, "\e[B"})
    :timer.sleep(200)
    GenServer.cast({:elita, session_node}, {:inject, "\e[B"})
    :timer.sleep(200)
    GenServer.cast({:elita, session_node}, {:inject, "\e[B"})
    :timer.sleep(200)
    GenServer.cast({:elita, session_node}, {:inject, "\e[B"})
    :timer.sleep(200)

    # Select with \r (Enter)
    GenServer.cast({:elita, session_node}, {:inject, "\r"})
    :timer.sleep(1500)

    # Ask which model
    GenServer.cast({:elita, session_node}, {:inject, "which model are you exactly\r"})
    :timer.sleep(2500)

    # Exit
    GenServer.cast({:elita, session_node}, {:inject, "/exit\r"})
    :timer.sleep(500)

  false ->
    :ok
end
