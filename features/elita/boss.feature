Feature: Boss

  @tape:boss
  Scenario: Engineer manager
    * > el boss

    * > el worker as dev

    * > el worker as qa

    * boss> you manage a software development team with a dev and a qa
      | ready |

    * boss> we need more test created
      | done |

    * boss> log
      | 📢 boss → qa | more tests |

    * dev> did you receive a task from boss?
      | no |

    * qa> did you receive a task from boss?
      | yes |

  @tape:boss2
  @wip
  Scenario: Office boss
    * > el

    * > el boss as michael

    * > el boss as dwight

    * > el worker as pam

    * > el worker as jim

    * michael> you manage dwight the assistant regional manager

    * dwight> you manage pam the receptionist and jim the salesman

    * michael> we need 50 copies of the quarterly sales report
      | done |

    * pam> did you receive a task to make copies?
      | yes |

    * jim> did you receive a task?
      | no |

    * michael> log
      | 📢 michael → dwight | 50 copies |

    * dwight> log
      | 📢 dwight → pam | 50 copies |
