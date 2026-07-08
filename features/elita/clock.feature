@time
Feature: Clock

  Scenario: Clock tells the time
    * > el
    * el> ask the clock what time it is
    * verify
      | 🤔 el → clock | what time is it     |
      | ✨ clock       | CLOCK ONLINE        |
      | ✨ clock       | 1:28 and 42 seconds |
