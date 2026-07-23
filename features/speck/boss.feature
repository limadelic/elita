@tape:delegate
Feature: Boss

  Scenario: speck reads, writes, and runs boss scenarios
    * > el speck

    * speck> exec boss

    * speck> log
      | 🧪 boss_spec                      | Tell Tool                                 |
      | 🤖 boss                           | Gets things done like a boss. Delegating. |
      | 🤖 worker                         | Team member who receives and remembers    |
      | 🎭 speck as tplan                 |                                           |
      | 🎭 speck as texec                 |                                           |
      | 🚀 boss_v1                        | as boss                                   |
      | 🚀 worker_v1                      | as worker                                 |
      | 📢 speck → boss_v1                | Delegate quarterly report task            |
      | 📢 boss_v1 → worker_v1            | Complete the quarterly report             |
      | ✨ boss_v1 → speck                | done                                      |
      | 🤔 speck → worker_v1              | Did you receive a task                    |
      | ✨ worker_v1 → speck              | Yes, I received a task                    |
      | 🚀 dev_worker_v2                  | as worker                                 |
      | 🚀 qa_worker_v2                   | as worker                                 |
      | 📢 boss_v2 → dev_worker_v2        | API endpoint implementation               |
      | 📢 boss_v2 → qa_worker_v2         | Login testing assignment                  |
      | ✨ boss_v2 → speck                | done                                      |
      | 🚀 infrastructure_lead_v3         | as worker                                 |
      | 🚀 qa_specialist_v3               | as worker                                 |
      | 📢 boss_v3 → infrastructure_lead  | optimize database queries                 |
      | 📢 boss_v3 → qa_specialist       | regression testing on payment module      |
      | ✨ boss_v3 → speck                | done                                      |
      | 🚀 boss_v7                        | as boss                                   |
      | 🚀 developer_v7                   | as worker                                 |
      | 📢 boss_v7 → developer_v7         | develop the application code              |
      | ✨ developer_v7 → speck           | develop the application code              |
      | 🚀 boss_v8                        | as boss                                   |
      | 📢 speck → boss_v8                | Delegate tasks to multiple workers        |
      | ✨ boss_v8 → speck                | done                                      |
      | ✏ boss_scenarios                  | Direct Delegation to Single Worker        |
      | ✨ speck                           | PASSED                                    |
