@delegate
Feature: Boss

  Scenario: Boss delegates to the right worker
    * > el
    * el> have a boss manage a dev and a qa
    * el> tell the boss we need more tests
    * el> ask the dev do you have a task from boss
    * el> ask the qa do you have a task from boss
    * verify
      | 📢 el → boss | we need more tests |
      | 📢 boss → qa | we need more tests |
      | ✨ dev | no, i don't have a task from boss |
      | ✨ qa | yes. i have a task from boss |

  @cascade
  Scenario: Boss delegates down the chain
    * > el
    * el> have michael the boss manage dwight the assistant regional manager
    * el> have dwight the boss manage pam the receptionist and jim the salesman
    * el> tell michael we need 50 copies of the quarterly sales report
    * el> ask pam do you have a task
    * el> ask jim do you have a task
    * verify
      | 📢 el → michael | 50 copies of the quarterly sales report |
      | 📢 michael → Dwight | get it done |
      | 📢 dwight → Pam | on his desk within the hour |
      | 🤔 el → pam | do you have a task |
      | ✨ pam | not at the moment |
      | 🤔 el → jim | do you have a task |
      | ✨ jim | no, i don't have a task |
