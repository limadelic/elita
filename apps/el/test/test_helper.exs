ExUnit.start()

# Start Tape.Writer if TAPE is set (for cassette replay in integration tests)
if System.get_env("TAPE") do
  try do
    {:ok, _} = Tape.Writer.start_link(nil)
  rescue
    UndefinedFunctionError ->
      # Tape.Writer might not be compiled in this context
      :ok
  end
end
