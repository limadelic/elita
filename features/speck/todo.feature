@specktodo
Feature: Speck todo

  Scenario: Speck verifies todo meets its spec
    * > el speck
    * speck> exec todo
    * verify
      | 🤔 speck → todo_v1 | Add 'buy groceries' |
      | 👀 todo | empty |
      | ✏️ todo = | buy groceries |
      | ✨ todo_v1 | added |
      | 🤔 speck → todo_v1 | Add 'buy milk' |
      | ✨ todo_v1 | added "buy milk" |
      | 🤔 speck → todo_v1 | Show me all my tasks |
      | ✨ todo_v1 | buy groceries 2. buy milk 3. walk dog |
      | 🤔 speck → todo_v2 | Add 'task 1' |
      | 🤔 speck → todo_v2 | Mark 'task 1' as complete |
      | ✏️ todo = | task 2 |
      | ✨ todo_v2 | marked complete |
      | ✨ speck | PASSED |
