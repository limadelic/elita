@malko @wip
Feature: Malkovich Malkovich

  Scenario: Malkovich Malkovich
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
    * malko> malkovich knock knock
    * malkovich:
      | knock knock |
      | who's there |
    * malko:
      | who's there |
    * malko> malkovich malko
    * malkovich:
      | malko     |
      | malko who |
    * malko:
      | malko who |
    * malko> malkovich malkovich
    * malkovich:
      | malkovich |
    * malko> /exit
    * malkovich> /exit

  Scenario: Tell between Malko and Malkovich
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
    * malko> tell malkovich i am malko
    * malko:
      | i am malko |
    * malkovich:
      | from malko |
      | i am malko |
    * malkovich> tell malko i am not
    * malkovich:
      | i am not |
    * malko:
      | from malkovich |
      | i am not |
    * malko> /exit
    * malkovich> /exit

  Scenario: Ask with emoji beat
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
    * malko> malkovich what is 2+2?
      | 🤔 | gather: ask to |
    * malkovich:
      | what is 2+2? |
    * malko:
      | 2 + 2 = 4 |
    * malko> /exit
    * malkovich> /exit
