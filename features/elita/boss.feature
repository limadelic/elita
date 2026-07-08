@delegate
Feature: Boss

  Scenario: Boss delegates to the right worker
    * > el
    * el> have a boss manage a dev and a qa
    * el> tell the boss we need more tests
    * el> ask the dev do you have a task from boss
      | no |
    * el> ask the qa do you have a task from boss
      | yes |

  @cascade
  Scenario: Boss delegates down the chain
    * > el
    * el> have michael the boss manage dwight the assistant regional manager
    * el> have dwight the boss manage pam the receptionist and jim the salesman
    * el> tell michael we need 50 copies of the quarterly sales report
    * el> ask pam do you have a task
      | copies |
    * el> ask jim do you have a task
      | no |
