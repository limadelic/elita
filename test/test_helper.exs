Logger.configure(level: :warning)
ExUnit.start(timeout: 300_000, max_cases: 1, exclude: :test, include: :main)

{:ok, _} = Tape.Writer.start_link(nil)

Code.require_file("tester.exs", __DIR__)
