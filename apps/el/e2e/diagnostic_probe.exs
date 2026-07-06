case Node.connect(:"el_claude@127.0.0.1") do
  true ->
    IO.puts("Step 1: Opening /model menu...")
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "/model\r"})
    :timer.sleep(2000)

    IO.puts("Step 2: Sending 5 to select Haiku...")
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "5"})
    :timer.sleep(500)

    IO.puts("Step 3: Pressing Enter...")
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "\r"})
    :timer.sleep(2000)

    IO.puts("Step 4: Sending simple query...")
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "test\r"})
    :timer.sleep(2000)

    IO.puts("Step 5: Checking footer with model query...")
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "/exit\r"})
    :timer.sleep(500)

  false ->
    IO.puts("Connection failed")
end
