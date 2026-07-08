Feature: Actor

  Scenario: speck reads, writes, and runs actor scenarios
    * > el speck
    * speck> exec actor
      | 🧪 actor_spec | professional actor          |
      | 🤖 actor      | Versatile actor             |
      | ✨ actor_v1    | Welcome to Ashworth House   |
      | ✨ actor_v3    | I'm Claude, an AI assistant |
      | 👀 scenario_1 | status: passed              |
      | 👀 scenario_3 | status: failed              |
      | 👀 scenario_5 | status: passed              |
      | ✨ speck       | CONDITIONAL PASS            |
