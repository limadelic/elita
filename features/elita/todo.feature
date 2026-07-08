@todo
Feature: Todo

  Scenario: Todo marks tasks complete
    * > el todo
    * todo> Add call dentist to my list
    * todo> Mark call dentist as done
    * todo> What do I need to do?
    * verify
      | ✨ todo | added |
      | ✨ todo | marked |
      | ✨ todo | no tasks |

  Scenario: Todo remembers tasks
    * > el todo
    * todo> Add buy groceries to my list
      | added |
    * todo> What do I need to do?
      | groceries |

  Scenario: Todo handles multiple tasks
    * > el todo
    * todo> Add buy milk to my list
      | added |
    * todo> Add walk dog to my list
      | added |
    * todo> What do I need to do?
      | milk |
      | dog |

