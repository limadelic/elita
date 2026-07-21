Feature: Ttt

  @tape:ttt
  Scenario: Alice and Bob play to completion
    * > el ttt as alice

    * > el ttt as bob

    * bob> alice is gonna be your opponent, wait for her move
      | I'm ready to play |

    * alice> start a game with bob, you are X, play first
      | I've started the game |

    * alice> log
      | 📢 alice → bob | Let's play tic-tac-toe |
      | 📢 alice → bob | taking the center      |
      | 📢 alice → bob | win with a diagonal    |

    * bob> log
      | 📢 bob → alice | center-right position |
      | 📢 bob → alice | top-right to build    |

    * alice> tell me: did the game finish and was it a win or tie?
      | game finished |
      | diagonal      |
