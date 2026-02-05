Logger.configure(level: :warning)
ExUnit.start(timeout: 300_000, max_cases: 1)

Code.require_file("tester.exs", __DIR__)
