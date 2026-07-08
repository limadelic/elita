@born
Feature: Birth

  Scenario: Mother gives birth to a baby
    * > el
    * el> get me a mother ready to give birth
    * el> tell the mother it's time
    * el> ask the baby how does it feel to be born
    * verify
      | 📢 el → mother | time |
      | 🤔 el → baby | feel |
      | ✨ baby | cry |
