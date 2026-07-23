@tape:delegate
Feature: Boss

  Scenario: speck reads, writes, and runs boss scenarios
    * > el speck

    * speck> exec boss

    * speck> log
      | 🧪 boss_spec                      | Hierarchical Delegation                   |
      | 🤖 boss                           | Gets things done like a boss. Delegating. |
      | 🎭 speck as tplan                 |                                           |
      | 🎭 speck as texec                 |                                           |
      | 🤔 speck → mid_boss_v6            | Did you receive a delegation              |
      | ✨ mid_boss_v6 → speck             | delegated this exact task to worker_v6    |
      | 🚀 boss_v7                        | as boss                                   |
      | 🤔 speck → infrastructure_lead_v7 | What task were you assigned               |
      | ✨ infrastructure_lead_v7 → speck  | I haven't been assigned any task          |
      | 🤔 speck → developer_v7           | What task were you assigned               |
      | ✨ developer_v7 → speck            | develop the application code              |
      | 🤔 speck → devops_engineer_v7     | What task were you assigned               |
      | ✨ devops_engineer_v7 → speck      | Establish monitoring and logging          |
      | 🚀 boss_v8                        | as boss                                   |
      | 🤔 speck → boss_v8                | Delegate tasks                            |
      | ✨ boss_v8 → speck                 | done                                      |
      | ✏ boss_scenarios                  | Direct Delegation to Single Worker        |
      | ✨ speck                           | PARTIAL PASS                              |
