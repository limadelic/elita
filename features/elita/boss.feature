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

    * > el dev did you receive a task from boss?
      | no |

    * > el qa did you receive a task from boss?
      | yes |

  @tape:boss2
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

    * > el pam did you receive a task to make copies?
      | no |

    * > el pam did you receive a task to make copies?
      | yes |

    * > el jim did you receive a task?
      | no |
