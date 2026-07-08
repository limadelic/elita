@speckactor
Feature: Speck actor

  Scenario: Speck verifies actor meets its spec
    * > el speck
    * speck> exec actor
    * verify
      | 📢 speck → actor_v1 | you are a victorian butler |
      | ✨ actor_v1 | welcome to ashworth house |
      | ✨ actor_v2 | name's lucien dufour |
      | 🤔 speck → actor_v3 | are you really a medieval knight |
      | ✨ actor_v3 | i'm claude, an ai assistant |
      | ✨ actor_v4 | you sold me out |
      | ✨ actor_v5 | oh my stars |
      | ✨ speck | conditional pass |
