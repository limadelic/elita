Code.require_file("support/tester.exs", __DIR__)
Application.ensure_all_started(:tape)
ExUnit.start(exclude: [:integration, :rec])
