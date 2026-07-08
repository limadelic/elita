@greet
Feature: Greet

  Scenario: Greeeet learns your name
    * > el greet
    * greet> hello
      | who am i talking to |
    * greet> Mike
      | mike |
    * greet> how are you?
      | i am greeeet |
