@tape:mother
Feature: Mother

  Scenario: speck reads, writes, and runs mother scenarios
    * > el speck

    * speck> exec mother

    * speck> log
      | 🧪 mother_spec     | Spawn Tool                                    |
      | 🤖 mother          | ready to give birth                           |
      | 🤖 baby            | newborn                                       |
      | 🎭 speck as tplan  |                                               |
      | ✏️ test_scenario_1 | Mother successfully spawns baby agent         |
      | ✏️ test_scenario_2 | Spawned baby agent exhibits expected behavior |
      | ✏️ test_scenario_3 | Baby agent is independently functional        |
      | ✏️ test_scenario_4 | Mother initiates birth event                  |
      | 🎭 speck as texec  |                                               |
      | 🚀 mother_v1       | as mother                                     |
      | 🚀 baby_v1         | as baby                                       |
      | ✨ baby_v1          | cry                                           |
