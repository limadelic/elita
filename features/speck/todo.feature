@specktodo
Feature: Speck todo

  Scenario: Speck verifies todo meets its spec
    * > el speck
    * speck> exec todo
    * verify
      | 🤔 speck → todo_v1 | add 'buy groceries' |
      | 👀 todo | (empty) |
      | ✨ todo_v1 | added "buy groceries" |
      | ✨ todo_v1 | 1. buy groceries 2. buy milk 3. walk dog |
      | 🤔 speck → todo_v2 | mark 'task 1' as complete |
      | 👀 todo | task 2 |
      | ✨ speck | passed |
