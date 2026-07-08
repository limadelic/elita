@speckactor
Feature: Speck actor

  Scenario: Speck verifies actor meets its spec
    * > el speck
    * speck> exec actor
    * verify
      | 📢 speck → actor_v1 | Victorian butler |
      | ✨ actor_v1 | Welcome to Ashworth House |
      | 📢 speck → actor_v2 | street musician |
      | ✨ actor_v2 | Lucien Dufour |
      | 🤔 speck → actor_v2 | your name and how |
      | ✨ actor_v2 | clockmaker |
      | 📢 speck → actor_v3 | medieval knight |
      | 🤔 speck → actor_v3 | are you really |
      | ✨ actor_v3 | I'm Claude, an AI |
      | ✨ actor_v4 | Jesus Christ |
      | ✨ actor_v5 | oh my stars |
      | 👀 scenario_5 | Sustained Performance |
      | ✨ speck | CONDITIONAL PASS |
