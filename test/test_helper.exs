Logger.configure(level: :warning)
ExUnit.start(timeout: 300_000)

Code.require_file("tester.exs", __DIR__)
