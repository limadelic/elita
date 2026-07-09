@tape:mother
Feature: Mother

  Scenario: speck reads, writes, and runs mother scenarios
    * > el speck
    * speck> exec mother
      | 🧪 mother_spec    | spawn       |
      | 🤖 mother         | spawn       |
      | 🎭 speck as tplan |             |
      | ✏️ scenario_1     |             |
      | 🎭 speck as texec |             |
      | 🚀 mother_v1      | as mother   |
      | 🚀 baby_v1        | as baby     |
      | ✨ baby_v1         | WAAAAAHHHHH |
      | 🚀 baby_v2        | as baby     |
      | ✨ speck           | PASSED      |
