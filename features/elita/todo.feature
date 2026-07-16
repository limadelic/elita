Feature: Todo

  @tape:todomark
  Scenario: Todo marks tasks complete
    * > el todo

    * todo> Add call dentist to my list
      | added |

    * todo> Mark call dentist as done
      | marked |

    * todo> What do I need to do?
      | no |

  @tape:todoremember
  Scenario: Todo remembers tasks
    * > el todo

    * todo> Add buy groceries to my list
      | added |

    * todo> What do I need to do?
      | groceries |

  @tape:todomultiple
  Scenario: Todo handles multiple tasks
    * > el todo

    * todo> Add buy milk to my list
      | added |

    * todo> Add walk dog to my list
      | added |

    * todo> What do I need to do?
      | milk |
      | dog  |
