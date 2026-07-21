Feature: Ttt

  @tape:ttt
  Scenario: Two players play to the end
    * > el ttt as alice

    * > el ttt as bob

    * bob> alice is gonna be your opponent, wait for her move
      | ready to play |

    * alice> start a game with bob, you are X, play first
      | game started |

    * alice> log
      | took the center |
      | _ \| X \| _     |

    * bob> log
      | corner      |
      | O \| _ \| _ |

    * alice> log
      | opposite corner |
      | _ \| _ \| X     |

    * bob> log
      | position 3  |
      | O \| _ \| O |

    * alice> log
      | position 7  |
      | X \| _ \| X |

    * bob> log
      | position 8  |
      | X \| O \| X |

    * alice> log
      | position 4  |
      | X \| X \| _ |

    * bob> log
      | position 6  |
      | X \| X \| O |

    * alice> log
      | position 2  |
      | O \| X \| O |
      | tie         |
