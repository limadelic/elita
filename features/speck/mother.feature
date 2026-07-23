@tape:mother
Feature: Mother

  Scenario: speck reads, writes, and runs mother scenarios
    * > el speck

    * speck> exec mother
      | 🧪 mother_spec | spawn |
      | 🤖 mother      | spawn |

    * verify
      | 🎭 speck as tplan  |                                               |
      | ✏️ test_scenario_1 | Mother successfully spawns baby agent         |
      | ✏️ test_scenario_2 | Spawned baby agent exhibits expected behavior |
      | ✏️ test_scenario_3 | Baby agent is independently functional        |
      | ✏️ test_scenario_4 | Mother initiates birth event                  |

    * verify
      | 🎭 speck as texec |           |
      | 🚀 mother_v1      | as mother |
      | 🚀 baby_v1        | as baby   |
      | ✨ baby_v1         | cry       |
