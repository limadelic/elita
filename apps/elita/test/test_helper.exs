Code.require_file("support/tester.exs", __DIR__)
Application.ensure_all_started(:tape)
Application.ensure_all_started(:matrix)
ExUnit.start(exclude: [:integration])
