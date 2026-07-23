@tape:delegate
Feature: Boss

  Scenario: speck reads, writes, and runs boss scenarios
    * > el speck

    * speck> exec boss

    * speck> log
      | 🧪 boss_spec              | Tell Tool                                              |
      | 🤖 boss                   | Gets things done like a boss                           |
      | 🤖 worker                 | Team member who receives and remembers                 |
      | 🎭 speck as tplan         |                                                        |
      | ✏️ test_scenario_1        | Boss delegates task to single worker                   |
      | ✏️ test_scenario_2        | Boss routes task based on worker specialization        |
      | ✏️ test_scenario_3        | Boss delegates through management hierarchy            |
      | ✏️ test_scenario_4        | Boss distributes multiple tasks to team                |
      | ✏️ test_scenario_5        | Boss confirms completion after delegation              |
      | 🎭 speck as texec         |                                                        |
      | 👀 test_scenario_1        | Boss delegates task to single worker                   |
      | 🚀 boss_v1                | as boss                                                |
      | 🚀 worker_v1              | as worker                                              |
      | 📢 speck → boss_v1        | Delegate this task to worker_v1                        |
      | 🤔 speck → worker_v1      | Did you receive a task to implement                    |
      | ✨ worker_v1 → speck       | Yes, I did                                             |
      | ✏️ test_scenario_1        | passed                                                 |
      | 🚀 boss_v2                | as boss                                                |
      | 🚀 dev_worker_v2          | as worker                                              |
      | 🚀 qa_worker_v2           | as worker                                              |
      | 🚀 ops_worker_v2          | as worker                                              |
      | 📢 speck → boss_v2        | You have a team with the following specialized workers |
      | 🤔 speck → dev_worker_v2  | Did you receive a task to implement OAuth2             |
      | ✨ dev_worker_v2 → speck   | Yes, I received that task. You assigned me             |
      | 🤔 speck → qa_worker_v2   | Did you receive a task to implement OAuth2             |
      | ✨ qa_worker_v2 → speck    | No, I didn't receive that task                         |
      | 🤔 speck → ops_worker_v2  | Did you receive a task to implement OAuth2             |
      | ✨ ops_worker_v2 → speck   | No, I didn't receive that task                         |
      | ✏️ test_scenario_2        | passed                                                 |
      | 🚀 senior_boss_v3         | as boss                                                |
      | 🚀 mid_boss_v3            | as boss                                                |
      | 🚀 worker_v3              | as worker                                              |
      | 📢 speck → senior_boss_v3 | You manage mid_boss_v3 who manages worker_v3           |
      | 📢 speck → mid_boss_v3    | Senior management has delegated work to you            |
      | 🤔 speck → worker_v3      | Did you receive a task to complete                     |
      | ✨ worker_v3 → speck       | Yes, I received that task from mid_boss_v3             |
      | ✏️ test_scenario_3        | passed                                                 |
      | 🚀 boss_v4                | as boss                                                |
      | 🚀 alice_v4               | as worker                                              |
      | 🚀 bob_v4                 | as worker                                              |
      | 🚀 charlie_v4             | as worker                                              |
      | 📢 speck → boss_v4        | Distribute these tasks to your team                    |
      | 🤔 speck → alice_v4       | What task were you assigned                            |
      | ✨ alice_v4 → speck        | I was assigned to design a new dashboard UI            |
      | 🤔 speck → bob_v4         | What task were you assigned                            |
      | ✨ bob_v4 → speck          | Yes, I received a task. I was assigned to fix          |
      | 🤔 speck → charlie_v4     | What task were you assigned                            |
      | ✨ charlie_v4 → speck      | Yes, I received a task. I was assigned to write        |
      | ✏️ test_scenario_4        | passed                                                 |
      | 🚀 boss_v5                | as boss                                                |
      | 🚀 worker_v5              | as worker                                              |
      | 🤔 speck → boss_v5        | Delegate this task to worker_v5                        |
      | ✨ boss_v5 → speck         | done                                                   |
      | 🤔 speck → worker_v5      | Did you receive a task to deploy hotfix                |
      | ✨ worker_v5 → speck       | Yes, I received that task                              |
      | ✏️ test_scenario_5        | passed                                                 |
      | ✨ speck                   | PASSED                                                 |
