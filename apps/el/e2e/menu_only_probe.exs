case Node.connect(:"el_claude@127.0.0.1") do
  true ->
    # Just open the menu and let it display for inspection
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "/model\r"})
    :timer.sleep(3000)
    
    # Exit without selection
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "/exit\r"})
    :timer.sleep(500)
  false ->
    :ok
end
