@wip
@tape:speckgreet
Feature: Greet

  @wip
  Scenario: speck reads, writes, and runs greet scenarios
    * > el speck
    * speck> exec greet
      | 🧪 greet_spec | Who am I talking |
      | 🤖 greet      | friendly greeter |
    * verify
      | 🎭 speck as tplan   |                      |
      | ✏️ greet_scenario_1 | Initial Question     |
      | ✏️ greet_scenario_2 | Name Acknowledgment  |
      | ✏️ greet_scenario_3 | State Persistence    |
      | ✏️ greet_scenario_4 | Continued Name Usage |
      | ✏️ greet_scenario_5 | Concise Warm         |
    * verify
      | 🎭 speck as texec |                  |
      | 🚀 greet_v        | as greet         |
      | ✨ greet_v         | who am i talking |
      | ✨ speck           | PASSED (5/5)     |
