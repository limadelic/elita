@tape:speckgreet
Feature: Greet

  Scenario: speck reads, writes, and runs greet scenarios
    * > el speck
    * speck> exec greet
      | 🧪 greet_spec     | Who am I talking |
      | 🤖 greet          | friendly greeter |
      | 🎭 speck as tplan             |                  |
      | ✏️ greet_scenario_1           |                  |
      | 🎭 speck as texec             |                  |
      | 🚀 greet_v        | as greet         |
      | ✨ greet_v         | who am i talking |
      | ✨ speck           | PASSED (5/5)     |
