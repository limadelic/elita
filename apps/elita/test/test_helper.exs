Logger.configure(level: :warning)

# Include :live tests only when LIVE=1 is set
live? = System.get_env("LIVE") == "1"
include_tags = if live?, do: [:main, :live], else: [:main]

# Live tests need longer timeout and real backend
if live? do
  System.put_env("LIVE", "1")
end

timeout = if live?, do: 600_000, else: 300_000

ExUnit.start(
  timeout: timeout,
  max_cases: 1,
  exclude: [:prose, :live, :napo, :dude],
  include: include_tags
)

{:ok, _} = Tape.Writer.start_link(nil)

Code.require_file("tester.exs", __DIR__)
