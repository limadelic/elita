Logger.configure(level: :warning)
ExUnit.start(timeout: 300_000, max_cases: 1, exclude: :test, include: :main)

Application.put_env(:elita, :tape, &Tape.play/3)

{:ok, _} = Tape.Writer.start_link(nil)

Code.require_file("tester.exs", __DIR__)
