Feature: Greet

  Scenario: Greeeet learns your name
    * > el greet

    * greet> hello
      | ✨ greet | who am i talking to |

    * greet> Mike
      | ✨ greet | wonderful to meet you, mike |

    * greet> how are you?
      | ✨ greet | i am greeeet |

  @tape:tape_miss
  Scenario: Tape replay behavior
    * > el greet
    * greet> hello
      | ✨ greet | hello from tape |

  @tape:tape_miss_live @tape_on_miss:live
  Scenario: Tape falls through to live on miss
    * > el greet
    * greet> hello
      | ✨ greet | hello from tape |
    * greet> goodbye
      | ✨ greet | response from stubbed server |

  @tape:tape_miss_swallow @tape_on_miss:swallow
  Scenario: Tape swallows miss and returns empty reply
    * > el greet
    * greet> hello
      | ✨ greet | hello from tape |
    * greet> unknown
      | greet> |
