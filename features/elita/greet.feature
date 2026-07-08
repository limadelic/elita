@greet
Feature: Greet

  Scenario: Greeeet learns your name
    * > el greet

    * greet> hello
      | ✨ greet | who am i talking to |

    * greet> Mike
      | ✨ greet | wonderful to meet you, mike |

    * greet> how are you?
      | ✨ greet | i am greeeet |
