@malko
@live
Feature: Portal

  Scenario: Through the tunnel into Malkovich
    * > el claude malko
      | ▐▛███▜▌     |
      | ▝▜█████▛▘   |
      | Claude Code |
      | Haiku       |
    * > el malko
    * malko> 1+1
    * malko:
      | 2 |
    * malko> /exit

  @wip
  Scenario: Ask the supervisor privately
    * > el claude malko
      | ▐▛███▜▌     |
      | ▝▜█████▛▘   |
      | Claude Code |
      | Haiku       |
    * > el malko
    * malko> @el 1+1
    * malko:
      | 🤔 malko → el.malko | 1+1 |
    * el.malko:
      | ✨ el.malko | 2 |
    * malko> /exit

  @wip
  Scenario: Supervisor asks the agent
    * > el claude malko
      | ▐▛███▜▌     |
      | ▝▜█████▛▘   |
      | Claude Code |
      | Haiku       |
    * > el malko
    * el> @malko 1+1
    * el:
      | 🤔 el.malko → malko | 1+1 |
    * malko:
      | ✨ malko | 2 |
      | 2 |
    * malko> /exit

  @wip
  Scenario: Root asks through el
    * > el claude malko
      | ▐▛███▜▌     |
      | ▝▜█████▛▘   |
      | Claude Code |
      | Haiku       |
    * > el malko
    * > el @malko 1+1
    * user:
      | 🤔 user → el.malko | 1+1 |
    * malko:
      | ✨ malko | 2 |
      | 2 |
    * malko> /exit

  @wip
  Scenario: Root tells through el
    * > el claude malko
      | ▐▛███▜▌     |
      | ▝▜█████▛▘   |
      | Claude Code |
      | Haiku       |
    * > el malko
    * > el tell @malko 1+1
    * user:
      | 📢 user → el.malko | 1+1 |
    * malko:
      | from user |
      | 1+1 |
    * malko> /exit
