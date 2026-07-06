# Test TYPE-TO-FILTER approach: filter menu by typing "haiku"
case Node.connect(:"el_claude@127.0.0.1") do
  true ->
    # Step 1: Open model menu
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "/model\r"})
    :timer.sleep(1200)

    # Step 2: Type "haiku" to filter menu
    # Raw bytes injection - no \r appended, acts as typed text
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "haiku"})
    :timer.sleep(500)

    # Step 3: Press Enter to select filtered option
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "\r"})
    :timer.sleep(1500)

    # Step 4: Query the model to verify
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "what model am i\r"})
    :timer.sleep(3000)

    # Step 5: Exit cleanly
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "/exit\r"})
    :timer.sleep(500)

  false ->
    :ok
end
