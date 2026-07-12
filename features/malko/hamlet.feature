@hamlet @malko @wip
Feature: Hamlet Ghost

  Scenario: Hamlet Ghost
    * > el claude ghost
      | ▐▛███▜▌     |
      | ▝▜█████▛▘   |
      | Claude Code |
      | Haiku       |
    * > el claude hamlet
      | ▐▛███▜▌     |
      | ▝▜█████▛▘   |
      | Claude Code |
      | Haiku       |
    * hamlet> ghost knock knock
    * ghost:
      | knock knock |
      | who's there |
    * hamlet:
      | who's there |
    * hamlet> ghost hamlet
    * ghost:
      | hamlet     |
      | hamlet who |
    * hamlet:
      | hamlet who |
    * hamlet> ghost ghost
    * ghost:
      | ghost |
    * hamlet> /exit
    * ghost> /exit

  Scenario: Tell fires and forgets
    * > el claude ghost
      | ▐▛███▜▌     |
      | ▝▜█████▛▘   |
      | Claude Code |
      | Haiku       |
    * > el claude hamlet
      | ▐▛███▜▌     |
      | ▝▜█████▛▘   |
      | Claude Code |
      | Haiku       |
    * hamlet> tell ghost hello from hamlet
    * hamlet:
      | hello from hamlet |
    * ghost:
      | from hamlet |
      | hello from hamlet |
    * hamlet> /exit
    * ghost> /exit
