@tape:mother
Feature: Mother

  @wip
  Scenario: speck reads, writes, and runs mother scenarios
    * > el speck
    * speck> exec mother
      | 🧪 mother_spec | spawn |
    * verify
      | 🎭 speck as tplan |                                 |
      | ✏️ scenario_1     | Mother Spawns Baby Successfully |
      | ✏️ scenario_2     | Spawned Baby Is Functional      |
      | ✏️ scenario_3     | Multiple Births Are Possible    |
      | ✏️ scenario_4     | Baby Agent Name Is Unique       |
    * verify
      | 🎭 speck as texec |             |
      | 🚀 mother_v1      | as mother   |
      | 🚀 baby_v1        | as baby     |
      | ✨ baby_v1         | WAAAAAHHHHH |
      | 🚀 baby_v2        | as baby     |
      | ✨ speck           | PASSED      |
