@tape:specktodo
Feature: Todo

  Scenario: speck reads, writes, and runs todo scenarios
    * > el speck
    * speck> exec todo
      | 🧪 todo_spec       | mem tools         |
      | 🤖 todo            | task manager      |
      | 🎭 speck as tplan  |                   |
      | ✏️ scenarios       |                   |
      | 🎭 speck as texec  |                   |
      | 🚀 todo_v1         | as todo           |
      | 🤔 speck → todo_v1 | groceries         |
      | ✨ todo_v1          | added             |
      | 🚀 todo_v2         | as todo           |
      | 🤔 speck → todo_v2 | What tasks        |
      | ✨ todo_v2          | buy groceries     |
      | ✨ speck            | PASSED            |
