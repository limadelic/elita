@malko
@autonomy
Feature: Ghost Autonomy

  # LIVE-ONLY: Autonomy requires live claude bash execution.
  # When wrapped claude receives an envelope "[from sender]\nmessage",
  # the system prompt instructs it to respond by running `el tell sender answer`.
  # Stub cassettes can capture I/O text but cannot execute bash commands,
  # so the message injection on the receiver end never happens in replay mode.
  # This loop is proven REAL with unscripted round-trips (rec15 verified),
  # but cassette replay is structurally impossible — kept @autonomy excluded.
  Scenario: Ghost replies to knock without prompt
    * > el claude yorick
      | ▐▛███▜▌     |
      | ▝▜█████▛▘   |
      | Claude Code |
      | Haiku       |
    * > el claude banquo
      | ▐▛███▜▌     |
      | ▝▜█████▛▘   |
      | Claude Code |
      | Haiku       |
    * banquo> tell yorick knock knock
    * banquo:
      | knock knock |
    * yorick:
      | from banquo |
      | knock knock |
    * yorick:
      | el tell banquo |
    * banquo:
      | from yorick |
      | who         |
