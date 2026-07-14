Feature: Greet

  Scenario: Greet learns your name
    Given a greet agent is running
    When I send "hello"
    Then I receive "who am i talking to"
    When I send "Mike"
    Then I receive "wonderful to meet you, mike"
    When I send "how are you?"
    Then I receive "i am greeeet"
