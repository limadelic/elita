@speckgreet
Feature: Speck greet

  Scenario: Speck verifies greet meets its spec
    * > el speck
    * speck> exec greet
    * verify
      | 🤔 speck → greet_v2 | hello, how are you          |
      | ✨ greet_v2          | who am i talking to         |
      | 🤔 speck → greet_v2 | my name is mike             |
      | ✨ greet_v2          | wonderful to meet you, mike |
      | 🤔 speck → greet_v2 | tell me a joke              |
      | ✨ greet_v2          | i am greeeet                |
      | ✨ speck             | passed (5/5)                |
