case Node.connect(:"el_claude@127.0.0.1") do
  true ->
    # Open model menu
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "/model\r"})
    :timer.sleep(1200)

    # Navigate to Haiku with raw escape sequences - 4 down arrows with 200ms gaps
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "\e[B"})
    :timer.sleep(200)
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "\e[B"})
    :timer.sleep(200)
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "\e[B"})
    :timer.sleep(200)
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "\e[B"})
    :timer.sleep(200)

    # Select with \r (Enter)
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "\r"})
    :timer.sleep(1500)

    # Ask which model
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "which model are you exactly\r"})
    :timer.sleep(2500)

    # Exit
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "/exit\r"})
    :timer.sleep(500)

  false ->
    :ok
end
