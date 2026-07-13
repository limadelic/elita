@malko @wip
Feature: Routing Emojis

  Scenario: Ask routing emits canonical format
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
    * malko> keeper what is the password?
      | 🤔 malko → keeper | what is the password? |
    * keeper:
      | ✨ keeper | the password is secret |
    * malko:
      | the password is secret |
    * malko> /exit
    * keeper> /exit

  Scenario: Tell routing emits canonical format
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
    * malko> tell keeper the code is 1234
      | 📢 malko → keeper | the code is 1234 |
    * malko:
      | the code is 1234 |
    * keeper:
      | from malko          |
      | the code is 1234 |
    * malko> /exit
    * keeper> /exit

  Scenario: Reply routing emits canonical format
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
    * malko> keeper who are you?
      | 🤔 malko → keeper | who are you? |
    * keeper:
      | ✨ keeper | I am the keeper |
    * malko:
      | I am the keeper |
    * malko> /exit
    * keeper> /exit
