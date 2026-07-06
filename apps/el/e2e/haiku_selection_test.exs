# Simple test: select Haiku via arrow navigation and verify

case Node.connect(:"el_claude@127.0.0.1") do
  true ->
    Logger.info("Connected to el node, starting Haiku selection test")

    # Open model menu
    Logger.info("Injecting /model")
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "/model\r"})
    :timer.sleep(1200)

    # Arrow down 4 times to reach Haiku (position 5)
    Logger.info("Sending 4 down arrows to navigate to Haiku")
    for i <- 1..4 do
      Logger.info("Arrow #{i}/4")
      GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "\e[B"})
      :timer.sleep(200)
    end

    # Select (Enter)
    Logger.info("Sending Enter to select Haiku")
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "\r"})
    :timer.sleep(1500)

    # Verify model
    Logger.info("Querying model with self-identification")
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "what is your exact model id\r"})
    :timer.sleep(3000)

    # Exit
    Logger.info("Exiting")
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "/exit\r"})
    :timer.sleep(500)

  false ->
    Logger.error("Failed to connect to el node")
end
