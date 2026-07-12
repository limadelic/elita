@malko @autonomy
Feature: Ghost Autonomy

  Scenario: Ghost replies to knock without prompt
    * > el claude yorick
      | ▐▛███▜▌     |
      | ▝▜█████▛▘   |
      | Claude Code |
      | Haiku       |
    * > el claude banquo
      | ▐▛███▜▌     |
      | ▝▜█████▛▘   |
      | Claude Code |
      | Haiku       |
    * banquo> tell yorick knock knock
    * banquo:
      | knock knock |
    * yorick:
      | from banquo |
      | knock knock |
    * yorick:
      | el tell banquo |
    * print transcript
    * banquo:
      | who's there |
