ExUnit.start()

# Start Tape.Writer if TAPE is set (for cassette replay in integration tests)
if System.get_env("TAPE") do
  {:ok, _} = Tape.Writer.start_link(nil)
end
