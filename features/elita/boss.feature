Feature: Boss

  @tape:boss
  Scenario: Software manager
    * > el boss

    * > el worker as dev

    * > el worker as qa

    * boss> you manage a software development team with a dev and a qa
      | ready |

    * boss> we need more test created
      | done |

    * boss> log
      | boss qa |

    * > el dev did you receive a task from boss?
      | no |

    * > el qa did you receive a task from boss?
      | yes |

  @tape:office
  Scenario: Office boss
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
