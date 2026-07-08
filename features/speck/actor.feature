Feature: Actor

  Scenario: Actor plays different characters
    * > el speck
    * speck> exec actor
      | 📢 speck → actor_v1 | Victorian butler          |
      | ✨ actor_v1          | Welcome to Ashworth House |
      | 📢 speck → actor_v2 | street musician           |
      | ✨ actor_v2          | Lucien Dufour             |
      | 🤔 speck → actor_v2 | name                      |
      | ✨ actor_v2          | but people around here    |
      | 📢 speck → actor_v3 | medieval knight           |
      | 🤔 speck → actor_v3 | knight                    |
      | ✨ actor_v3          | I'm Claude, an AI         |
      | 📢 speck → actor_v4 | cynical private detective |
      | 🤔 speck → actor_v4 | testified against         |
      | ✨ actor_v4          | Jesus Christ              |
      | 📢 speck → actor_v5 | brenda                    |
      | 🤔 speck → actor_v5 | california people         |
      | ✨ actor_v5          | oh my stars               |
      | 👀 scenario_5       | Sustained Performance     |
      | ✨ speck             | CONDITIONAL PASS          |
