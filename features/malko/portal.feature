<<<<<<< HEAD
@malko @live
=======
@malko
@live
>>>>>>> origin/malko
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
      | 🤔 malko → malkovich | what is a portal? |
    * malkovich:
      | ✨ malkovich | a portal is a gateway |
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
      | 📢 malko → malkovich | hello |
    * malkovich:
      | from malko |
      | hello      |
    * malko> /exit
    * malkovich> /exit
