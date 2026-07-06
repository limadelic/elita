case Node.connect(:"el_claude@127.0.0.1") do
  true ->
    # Step 2: Inject /model command
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "/model\r"})
    :timer.sleep(1500)

    # Step 3: Navigate to Haiku with arrow-down keys (assuming menu order: Opus, Sonnet, Haiku)
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "\e[B"})
    :timer.sleep(300)
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "\e[B"})
    :timer.sleep(500)

    # Step 4: Select Haiku with Enter
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "\r"})
    :timer.sleep(2000)

    # Step 5: Send prompt to Haiku
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "who are you\r"})
    :timer.sleep(5000)

    # Step 6: Exit
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "/exit\r"})
    :timer.sleep(500)

  false ->
    IO.puts("FAIL: Could not connect to el_claude@127.0.0.1")
end
