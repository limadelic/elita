<<<<<<< HEAD
@malko @live
=======
@malko
@live
>>>>>>> origin/malko
Feature: Door

  Scenario: First trip into Malkovich
    * > el claude malko
      | ▐▛███▜▌     |
      | ▝▜█████▛▘   |
      | Claude Code |
      | Haiku       |
    * malko> /exit

  Scenario: Tell through the door
    * > el claude malko
      | ▐▛███▜▌     |
      | ▝▜█████▛▘   |
      | Claude Code |
      | Haiku       |
    * > el claude keeper
      | ▐▛███▜▌     |
      | ▝▜█████▛▘   |
      | Claude Code |
      | Haiku       |
    * malko> tell keeper open sesame
      | 📢 malko → keeper | open sesame |
    * malko:
      | open sesame |
    * keeper:
      | from malko  |
      | open sesame |
    * malko> /exit
    * keeper> /exit

  Scenario: Ask through the door
    * > el claude malko
      | ▐▛███▜▌     |
      | ▝▜█████▛▘   |
      | Claude Code |
      | Haiku       |
    * > el claude keeper
      | ▐▛███▜▌     |
      | ▝▜█████▛▘   |
      | Claude Code |
      | Haiku       |
    * malko> keeper what is sesame?
      | 🤔 malko → keeper | what is sesame? |
    * keeper:
      | ✨ keeper | sesame is a magic word |
    * malko:
      | sesame is a magic word |
    * malko> /exit
    * keeper> /exit
