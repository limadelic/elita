Feature: Ttt

  @tape:ttt
  Scenario: Alice and Bob play to completion
    * > el

    * el> ttt as alice

    * el> ttt as bob

    * el> alice start a game with bob, you are X, play first
      | started the game |

    * el> bob alice is gonna be your opponent, wait for her move
      | waiting for alice |

    * el> alice tell me: did the game finish and was it a win or tie?
      | game finished |
      | diagonal |
