Feature: Ttt

  @tape:ttt
  Scenario: Alice and Bob play to completion
    * > el

    * > el ttt as alice

    * > el ttt as bob

    * > el alice start a game with bob, you are X, play first
      | I've started the game |

    * > el bob alice is gonna be your opponent, wait for her move
      | I'm ready to play |

    * > el alice tell me: did the game finish and was it a win or tie?
      | game finished |
      | diagonal      |
