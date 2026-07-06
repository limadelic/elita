case Node.connect(:"el_claude@127.0.0.1") do
  true ->
    # Inject "hola" text
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "hola"})
    :timer.sleep(300)
    # Then inject Ctrl+U to clear
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, <<21>>})
    :timer.sleep(100)
    # Then inject /exit\r to exit
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "/exit\r"})
    :timer.sleep(500)
  false ->
    :ok
end
