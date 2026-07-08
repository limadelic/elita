@speckgreet
Feature: Speck greet

  Scenario: Speck verifies greet meets its spec
    * > el speck
    * speck> exec greet:
      | who am i talking to |
      | stores the name mike |
      | i am greeeet |
      | passed |
