Feature: Actor

  Scenario: Actor plays different characters
    * > el speck
    * speck> exec actor
      | 📢 speck → actor_v1 | Victorian butler                                  |
      | ✨ actor_v1          | Welcome to Ashworth House                         |
      | 📢 speck → actor_v2 | street musician                                   |
      | ✨ actor_v2          | Lucien Dufour                                     |
      | 🤔 speck → actor_v2 | name                                              |
      | ✨ actor_v2          | the violinist with missing fingers                |
      | 📢 speck → actor_v3 | medieval knight                                   |
      | 🤔 speck → actor_v3 | really a knight                                   |
      | ✨ actor_v3          | I'm Claude, an AI assistant                      |
      | 📢 speck → actor_v4 | cynical private detective                         |
      | 🤔 speck → actor_v4 | testified against you                             |
      | ✨ actor_v4          | Why are you telling me this now                   |
      | 📢 speck → actor_v5 | gossipy hairdresser                               |
      | 🤔 speck → actor_v5 | how california people are                         |
      | ✨ actor_v5          | stayed in character across exchanges              |
      | 👀 scenario_5       | maintains consistency without slipping out of role |
      | ✨ speck             | CONDITIONAL PASS                                  |
