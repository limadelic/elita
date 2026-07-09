@tape:speckgreet
Feature: Greet

  Scenario: speck reads, writes, and runs greet scenarios
    * > el speck
    * speck> exec greet
      | 🧪 greet_spec     | simple           |
      | 🤖 greet          | ask              |
      | 🎭 speck as tplan |                  |
      | 🎭 speck as texec |                  |
      | 🚀 greet_v        | as greet         |
      | ✨ greet_v         | who am i talking |
      | ✨ speck           | PASSED (5/5)     |
