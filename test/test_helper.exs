Logger.configure(level: :warning)
ExUnit.start(timeout: 300_000, max_cases: 1)

# mix test_fast — excludes @tag :integration (LLM-heavy flows)

Code.require_file("tester.exs", __DIR__)
