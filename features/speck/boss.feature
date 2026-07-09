@tape:speckboss
Feature: Boss

  Scenario: speck reads, writes, and runs boss scenarios
    * > el speck
    * speck> exec boss
      | 🧪 boss_spec | Hierarchical Delegation                          |
      | 🤖 boss      | Gets things done like a boss. Delegating.        |
      | 🤖 worker    | Team member who takes tasks and reports honestly |
    * verify
      | 🎭 speck as tplan |                                         |
      | ✏️ scenario_1     | Single Level Direct Delegation          |
      | ✏️ scenario_2     | Role-Based Task Routing to Dev          |
      | ✏️ scenario_3     | Role-Based Task Routing to QA           |
      | ✏️ scenario_4     | Hierarchical Delegation Through         |
      | ✏️ scenario_5     | Boss Reports Task Completion            |
      | ✏️ scenario_6     | Multiple Tasks to Different Specialists |
    * verify
      | 🎭 speck as texec      |                 |
      | 🚀 boss_v1             | as boss         |
      | 🚀 worker_v1           | as worker       |
      | 📢 boss_v1 → worker_v1 | Write API       |
      | ✨ speck                | ALL 6 SCENARIOS |
