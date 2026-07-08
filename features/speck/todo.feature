@tape:specktodo
Feature: Todo

  Scenario: Todo tracks tasks - add task, confirm addition, list shows task
    * > el speck
    * speck> exec todo
      | 👀 scenarios       | pending    |
      | 🤔 speck → todo_v1 | groceries  |
      | 👀 todo            | (empty)    |
      | ✨ todo_v1          | added      |
      | 👀 todo            | walk       |
      | 🤔 speck → todo_v2 | What tasks |
      | ✨ speck            | PASSED     |
