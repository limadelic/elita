Feature: Ttt

  @tape:ttt
  Scenario: Two players play to the end
    * > el ttt as alice

    * > el ttt as bob

    * bob> alice is gonna be your opponent, wait for her move
      | I'm ready to play |

    * alice> start a game with bob, you are X, play first
      | I've started the game |

    * alice> log
      | 📢 alice → bob | Let's play tic-tac-toe. I'm X and I'll go first. Here's my opening move: |
      |                | X \| _ \| _                                                              |
      |                | _ \| _ \| _                                                              |
      |                | _ \| _ \| _                                                              |

    * bob> log
      | 📢 bob → alice | Hi Alice! Great, let's play! Here's my move: |
      |                | X \| _ \| _                                  |
      |                | _ \| _ \| O                                  |
      |                | _ \| _ \| _                                  |

    * alice> log
      | 📢 alice → bob | Nice move, Bob! Here's my response: |
      |                | X \| _ \| _                         |
      |                | _ \| X \| O                         |
      |                | _ \| _ \| _                         |

    * bob> log
      | 📢 bob → alice | I'm taking the top-right to build my defense. |
      |                | X \| _ \| O                                   |
      |                | _ \| X \| O                                   |
      |                | _ \| _ \| _                                   |

    * alice> log
      | 📢 alice → bob | I'm taking the bottom-right corner and I win with a diagonal! |
      |                | X \| _ \| O                                                   |
      |                | _ \| X \| O                                                   |
      |                | _ \| _ \| X                                                   |
