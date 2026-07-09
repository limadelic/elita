@tape:speckboss
Feature: Boss

  Scenario: speck reads, writes, and runs boss scenarios
    * > el speck
    * speck> exec boss
      | 🧪 boss_spec               | delegates               |
      | 🤖 boss                    | never ask               |
      | 🤖 worker                  | takes tasks             |
      | 🎭 speck as tplan          |                         |
      | 🎭 speck as texec          |                         |
      | 🚀 boss_v1                 | as boss                 |
      | 🚀 worker_v1               | as worker               |
      | 📢 boss_v1 → worker_v1     | quarterly report        |
      | ✨ boss_v1                  | done                    |
      | ✨ worker_v1                | I have a task           |
      | 🚀 boss_v2                 | as boss                 |
      | 📢 boss_v2 → dev_worker_v2 | authentication          |
      | ✨ qa_worker_v2             | No, I don't have a task |
      | ✨ speck                    | PASSED                  |
