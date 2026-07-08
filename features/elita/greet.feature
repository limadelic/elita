@greet
Feature: Greet

  Scenario: Greeeet learns your name
    * > el greet
    * greet> hello
    * greet> Mike
    * greet> how are you?
    * verify
      | ✨ greet | who am i talking to |
      | ✨ greet | wonderful to meet you, mike |
      | ✨ greet | i am greeeet |
