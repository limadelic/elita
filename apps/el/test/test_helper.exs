Logger.configure(level: :warning)

include_tags = if System.get_env("LIVE") == "1", do: [:main, :live], else: [:main]

timeout = 60_000

ExUnit.start(
  timeout: timeout,
  max_cases: 1,
  exclude: [:live],
  include: include_tags
)

{:ok, _} = Tape.Writer.start_link(nil)
