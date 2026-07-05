Logger.configure(level: :warning)

# Include :live tests only when LIVE=1 is set
include_tags = if System.get_env("LIVE") == "1", do: [:main, :live], else: [:main]

# Live tests need longer timeout for agent orchestration
timeout = if System.get_env("LIVE") == "1", do: 600_000, else: 300_000
ExUnit.start(timeout: timeout, max_cases: 1, exclude: [:prose, :live, :napo], include: include_tags)

{:ok, _} = Tape.Writer.start_link(nil)

Code.require_file("tester.exs", __DIR__)
