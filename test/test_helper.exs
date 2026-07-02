Logger.configure(level: :warning)

# Include :live tests only when LIVE=1 is set
include_tags = if System.get_env("LIVE") == "1", do: [:main, :live], else: :main

ExUnit.start(timeout: 300_000, max_cases: 1, exclude: :test, include: include_tags)

{:ok, _} = Tape.Writer.start_link(nil)

Code.require_file("tester.exs", __DIR__)
