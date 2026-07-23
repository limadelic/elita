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
      | ✏️ test_scenario_1                | Boss delegates task to single worker      |
      | ✏️ test_scenario_2                | Boss routes task based on specialization  |
      | ✏️ test_scenario_3                | Boss delegates through hierarchy          |
      | ✏️ test_scenario_4                | Boss distributes multiple tasks to team   |
      | ✏️ test_scenario_5                | Boss confirms completion after delegation |
      | 🎭 speck as texec                 |                                           |
      | 🚀 boss_v1                        | as boss                                   |
      | 🚀 worker_v1                      | as worker                                 |
      | 📢 speck → boss_v1                | Delegate task to worker_v1                |
      | 📢 boss_v1 → worker_v1            | Quarterly report task assignment           |
      | ✨ boss_v1 → speck                | done                                      |
      | 🤔 speck → worker_v1              | Did you receive a task from boss          |
      | ✨ worker_v1 → speck              | Yes, received task assignment             |
      | ✏️ test_scenario_1                | passed                                    |
      | 🚀 dev_worker_v2                  | as worker                                 |
      | 🚀 qa_worker_v2                   | as worker                                 |
      | 📢 boss_v2 → dev_worker_v2        | API endpoint implementation               |
      | 📢 boss_v2 → qa_worker_v2         | Login testing assignment                  |
      | ✨ boss_v2 → speck                | done                                      |
      | ✏️ test_scenario_2                | passed                                    |
      | 🚀 infrastructure_lead_v3         | as worker                                 |
      | 🚀 qa_specialist_v3               | as worker                                 |
      | 📢 boss_v3 → infrastructure_lead  | optimize database queries                 |
      | 📢 boss_v3 → qa_specialist       | regression testing on payment module      |
      | ✏️ test_scenario_3                | passed                                    |
      | ✏️ test_scenario_4                | passed                                    |
      | ✏️ test_scenario_5                | passed                                    |
      | ✨ speck                           | PASSED                                    |
