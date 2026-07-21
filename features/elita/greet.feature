Feature: Greet

  Scenario: Greeeet learns your name
    * > el greet

    * greet> hello
      | who am i talking to |

    * greet> Mike
      | wonderful to meet you |

    * greet> how are you?
      | i am greeeet |
