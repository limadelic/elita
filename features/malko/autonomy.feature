@malko @wip @autonomy
Feature: Ghost Autonomy

  Scenario: Ghost replies to knock without prompt
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
    * hamlet:
      | who's there |
