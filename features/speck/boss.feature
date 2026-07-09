@tape:speckboss
Feature: Boss

  Scenario: speck reads, writes, and runs boss scenarios
    * > el speck
    * speck> exec boss
      | 🧪 boss_spec               | Tell Tool                       |
      | 🤖 boss                    | Delegating                      |
      | 🎭 speck as tplan          |                                 |
      | ✏️ scenario_1              | Boss delegates to single worker |
      | 🎭 speck as texec          |                                 |
      | 🚀 boss_v1                 | as boss                         |
      | 🚀 worker_v1               | as worker                       |
      | 📢 boss_v1 → worker_v1     | Implement login feature         |
      | ✨ boss_v1                  | done                            |
      | ✨ worker_v1                | my role as a team member        |
      | 🚀 boss_v2                 | as boss                         |
      | 📢 boss_v2 → dev_worker_v2 | Develop REST API                |
      | ✨ qa_worker_v2             | adopted the role                |
      | ✨ speck                    | VERIFIED AND PASSING            |
