System.delete_env("ANTHROPIC_API_KEY")

ExUnit.start()

Application.stop(:elita)
Application.stop(:matrix)

Specs.Cover.start()

Application.ensure_all_started(:matrix)
Application.ensure_all_started(:elita)

Code.require_file("support/helper.exs", __DIR__)
