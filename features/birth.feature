@birth
Feature: Birth

  Scenario: Mother gives birth to a baby
    * > el
    * el> spawn mother
    * el> ask the mother it's time to give birth:
      | time |
    * el> ask the baby spank:
      | cry |
