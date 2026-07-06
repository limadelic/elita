case Node.connect(:"el_claude@127.0.0.1") do
  true ->
    # Open model menu
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "/model\r"})
    :timer.sleep(1200)

    # Navigate to Haiku (4 down arrows) then select with "s" for this session
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "\e[B\e[B\e[B\e[B"})
    :timer.sleep(600)
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "s"})
    :timer.sleep(1500)

    # Ask which model
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "which model are you\r"})
    :timer.sleep(2500)

    # Exit
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "/exit\r"})
    :timer.sleep(500)

  false ->
    :ok
end
