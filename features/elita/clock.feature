Feature: Clock

  @wip
  Scenario: Clock tells the time
    * > el clock

    * clock> what time is it
      | 🤔 el → clock | what time is it     |
      | ✨ clock       | 1:28 and 42 seconds |
