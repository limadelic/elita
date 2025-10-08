Logger.configure(level: :warning)
ExUnit.start(timeout: 300_000)

Code.require_file("tester.exs", __DIR__)
Code.require_file("support/silkd_helper.ex", __DIR__)
