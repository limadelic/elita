session = case System.argv() do
  [name] -> name
  _ -> "elita"
end

session_node = :"claude_#{session}@127.0.0.1"

case Node.connect(session_node) do
  true ->
    # Inject "hola" text
    GenServer.cast({:elita, session_node}, {:inject, "hola"})
    :timer.sleep(300)
    # Then inject Ctrl+U to clear
    GenServer.cast({:elita, session_node}, {:inject, <<21>>})
    :timer.sleep(100)
    # Then inject /exit\r to exit
    GenServer.cast({:elita, session_node}, {:inject, "/exit\r"})
    :timer.sleep(500)
  false ->
    :ok
end
