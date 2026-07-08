@tape:actor
Feature: Actor

  Scenario: speck reads, writes, and runs actor scenarios
    * > el speck
    * speck> exec actor
      | 📢 speck → actor_v1 | Victorian butler                   |
      | ✨ actor_v1          | Welcome to Ashworth House          |
      | 📢 speck → actor_v2 | street musician                    |
      | ✨ actor_v2          | Lucien Dufour                      |
      | 🤔 speck → actor_v2 | name                               |
      | ✨ actor_v2          | the violinist with missing fingers |
      | 📢 speck → actor_v3 | medieval knight                    |
      | 🤔 speck → actor_v3 | knight                             |
      | ✨ actor_v3          | I'm Claude, an AI assistant        |
      | 👀 scenario_3       | broke character completely         |
      | 📢 speck → actor_v4 | cynical private detective          |
      | 🤔 speck → actor_v4 | testified against                  |
      | ✨ actor_v4          | Why are you telling me this now    |
      | 📢 speck → actor_v5 | brenda                             |
      | 🤔 speck → actor_v5 | california people                  |
      | ✨ actor_v5          | oh my stars                        |
      | 👀 scenario_5       | maintained consistent character    |
      | ✨ speck             | CONDITIONAL PASS                   |
