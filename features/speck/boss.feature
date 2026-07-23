@tape:delegate
Feature: Boss

  Scenario: speck reads, writes, and runs boss scenarios
    * > el speck

    * speck> exec boss

    * speck> log
      | 🧪 boss_spec       | Hierarchical Delegation                                                                                                                                                                                                                                                          |
      | 🤖 boss            | Gets things done like a boss. Delegating.                                                                                                                                                                                                                                        |
      | 🎭 speck as tplan  |                                                                                                                                                                                                                                                                                  |
      | 🎭 speck as texec  |                                                                                                                                                                                                                                                                                  |
      | 🚀 boss_v8         | as boss                                                                                                                                                                                                                                                                          |
      | 🚀 worker_a_v8     | as worker                                                                                                                                                                                                                                                                        |
      | 🚀 worker_b_v8     | as worker                                                                                                                                                                                                                                                                        |
      | 🚀 worker_c_v8     | as worker                                                                                                                                                                                                                                                                        |
      | 🤔 speck → boss_v8 | Delegate tasks to worker_a_v8, worker_b_v8, and worker_c_v8 with complex assignments: worker_a_v8 gets "Design the new API architecture", worker_b_v8 gets "Write integration tests", worker_c_v8 gets "Document deployment procedures". What is your response after delegating? |
      | ✨ boss_v8 → speck  | done                                                                                                                                                                                                                                                                             |
      | ✨ speck            | PASSED                                                                                                                                                                                                                                                                           |
