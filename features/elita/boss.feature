Feature: Boss

  @tape:boss
  Scenario: Boss manages and delegates
    * > el boss

    * boss> you manage a software development team with a dev and a qa
      | I'm ready to manage the team |

    * boss> we need more test created
      | Done |

  @tape:office
  Scenario: Boss delegates down the chain
    * > el

    * el> have michael the boss manage dwight the assistant regional manager

    * el> have dwight the boss manage pam the receptionist and jim the salesman

    * el> tell michael we need 50 copies of the quarterly sales report
      | 📢 el → michael     | 50 copies of the quarterly sales report |
      | 📢 michael → Dwight | get it done                             |

    * el> ask pam do you have a task
      | 📢 dwight → Pam | 50 copies of the quarterly sales report |
      | ✨ pam           | I'll get these done right away          |
      | ✨ dwight        | Pam will have those copies ready        |
      | 🤔 el → pam     | do you have a task                      |
      | ✨ pam           | not at the moment                       |

    * el> ask jim do you have a task
      | 🤔 el → jim | do you have a task      |
      | ✨ jim       | no, i don't have a task |
