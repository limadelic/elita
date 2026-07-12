@malko
Feature: Portal

  Scenario: Through the tunnel into Malkovich
    * > el claude malko
      | ▐▛███▜▌     |
      | ▝▜█████▛▘   |
      | Claude Code |
      | Haiku       |
    * > el malko
    * malko> 1+1
      | 2 |
    * malko> /exit

  Scenario: Tell across portal agents
    * > el claude malkovich
      | ▐▛███▜▌     |
      | ▝▜█████▛▘   |
      | Claude Code |
      | Haiku       |
    * > el claude malko
      | ▐▛███▜▌     |
      | ▝▜█████▛▘   |
      | Claude Code |
      | Haiku       |
    * malko> tell malkovich hello
      | 🤔 | tell malkovich hello |
    * malkovich:
      | from malko |
      | hello      |
    * malko> /exit
    * malkovich> /exit
