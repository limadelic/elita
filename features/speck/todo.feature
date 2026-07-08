@specktodo
Feature: Speck todo

  Scenario: Speck verifies todo meets its spec
    * > el speck
    * speck> exec todo
    * verify
      | 👀 scenarios | pending |
      | 🤔 speck → todo_v1 | groceries |
      | 👀 todo | (empty) |
      | ✨ todo_v1 | added |
      | 👀 todo | walk |
      | 🤔 speck → todo_v2 | What tasks |
      | ✨ speck | PASSED |
