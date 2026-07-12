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

  Scenario: Ask across portal agents
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
    * malko> malkovich what is a portal?
      | 🤔 | gather: ask to |
    * malkovich:
      | what is a portal? |  |
      | ✨                | ask reply to |
    * malko:
      | a portal is a gateway |
    * malko> /exit
    * malkovich> /exit

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
      | 📢 | inject to |
    * malkovich:
      | from malko |
      | hello      |
    * malko> /exit
    * malkovich> /exit
