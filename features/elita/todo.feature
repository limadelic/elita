@wip
Feature: Todo

  @tape:todomark
  Scenario: Todo marks tasks complete
    * > el todo

    * todo> Add call dentist to my list

    * todo> log
      | 👀 todo | (empty)      |
      | ✏️ todo | call dentist |

    * todo> Mark call dentist as done

    * todo> log
      | 👀 todo | call dentist |
      | ✏️ todo | (empty)      |

    * todo> What do I need to do?
      | no |

    * todo> log
      | 👀 todo | (empty) |

  @tape:todoremember
  Scenario: Todo remembers tasks
    * > el todo

    * todo> Add buy groceries to my list

    * todo> log
      | 👀 todo | (empty)       |
      | ✏️ todo | buy groceries |

    * todo> What do I need to do?
      | groceries |

    * todo> log
      | 👀 todo | buy groceries |

  @tape:todomultiple
  Scenario: Todo handles multiple tasks
    * > el todo

    * todo> Add buy milk to my list

    * todo> log
      | 👀 todo | (empty)  |
      | ✏️ todo | buy milk |

    * todo> Add walk dog to my list

    * todo> log
      | 👀 todo | buy milk |
      | ✏️ todo | walk dog |

    * todo> What do I need to do?
      | milk |
      | dog  |

    * todo> log
      | 👀 todo | walk dog |
