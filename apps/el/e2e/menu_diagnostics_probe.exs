# Comprehensive menu input diagnostics
# Logs every injection attempt and captures responses

case Node.connect(:"el_claude@127.0.0.1") do
  true ->
    Logger.info("=== MENU DIAGNOSTICS START ===")

    # Open model menu
    Logger.info("Step 1: Opening /model menu")
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "/model\r"})
    :timer.sleep(1000)

    # Test text input - single character
    Logger.info("Step 2a: Injecting single char 'h'")
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "h"})
    :timer.sleep(300)

    # Test another character
    Logger.info("Step 2b: Injecting 'a'")
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "a"})
    :timer.sleep(300)

    # Test backspace (in case we need to clear)
    Logger.info("Step 2c: Injecting backspace (^H)")
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "\x08"})
    :timer.sleep(300)

    # Test number digit
    Logger.info("Step 3: Injecting digit '2'")
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "2"})
    :timer.sleep(300)

    # Test up arrow
    Logger.info("Step 4a: Injecting up arrow (\\e[A)")
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "\e[A"})
    :timer.sleep(300)

    # Test down arrow
    Logger.info("Step 4b: Injecting down arrow (\\e[B)")
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "\e[B"})
    :timer.sleep(300)

    # Test SS3 format arrow
    Logger.info("Step 5: Injecting SS3 down arrow (\\eOB)")
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "\eOB"})
    :timer.sleep(300)

    # Try to select
    Logger.info("Step 6: Injecting Enter to select")
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "\r"})
    :timer.sleep(1000)

    # Ask what model we're on
    Logger.info("Step 7: Querying current model")
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "what is your model\r"})
    :timer.sleep(2000)

    # Exit
    Logger.info("Step 8: Exiting with /exit")
    GenServer.cast({:claude, :"el_claude@127.0.0.1"}, {:inject, "/exit\r"})
    :timer.sleep(500)

    Logger.info("=== MENU DIAGNOSTICS END ===")

  false ->
    Logger.error("Failed to connect to el_claude node")
end
