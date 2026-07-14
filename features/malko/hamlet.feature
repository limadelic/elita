@hamlet
@malko
@live
Feature: Hamlet Ghost Tell

  Scenario: Tell fires and forgets with envelope and tell-back
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
    * hamlet> tell ghost knock knock
    * hamlet:
      | knock knock |
    * ghost:
      | from hamlet |
      | knock knock |
    * ghost> tell hamlet who's there
    * ghost:
      | who's there |
    * hamlet:
      | from ghost  |
      | who's there |
    * hamlet> /exit
    * ghost> /exit
