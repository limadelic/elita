Feature: Mother

  Scenario: Mother spawns baby agents - each baby cries and identifies itself
    * > el speck
    * speck> exec mother
      | 📢 speck → mother_v1 | time to give birth   |
      | ✨ mother_v1          | Welcome to the world |
      | 🤔 speck → baby_v1   | What are you doing   |
      | ✨ baby_v1            | WAAAAAHHHHH          |
      | 🤔 speck → baby_v2   | Are you baby_v2      |
      | ✨ baby_v2            | Me baby_v2! Me cry   |
      | 🤔 speck → baby_v3   | Are you baby_v3      |
      | ✨ baby_v3            | I am baby_v3         |
      | ✨ speck              | PASSED               |
