@delegate
Feature: Boss

  Scenario: Boss delegates to the right worker
    * > el
    * el> have a boss manage a dev and a qa
    * el> tell the boss we need more tests
    * el> ask the dev do you have a task from boss:
      | no |
    * el> ask the qa do you have a task from boss:
      | yes |
