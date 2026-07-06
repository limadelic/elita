case Node.connect(:"el_claude@127.0.0.1") do
  true ->
    # Inject a simple test message via distribution
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "test inject\r"})
    :timer.sleep(2000)

    # Clear and exit
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, ""})
    :timer.sleep(200)
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "/exit\r"})
    :timer.sleep(500)

  false ->
    :ok
end
