@tictactoe
Feature: Ttt

  Scenario: Two players play to the end
    * > el

    * el> get me two ttt players named alice and bob
      | 📢 el → alice | character   |
      | 📢 el → bob   | character   |
      | 📢 alice → el | opening     |
      | ✨ bob         | tic-tac-toe |

    * el> tell bob alice is gonna be your opponent, wait for her move
      | 📢 el → bob    | Alice says   |
      | 📢 bob → Alice | Nice opening |
      | 📢 alice → bob | Good move    |

    * el> tell alice start a game with bob, you are X, play first
      | 📢 el → alice |  |

    * el> ask alice did the game finish and was it a win or a tie
      | 🤔 el → alice |  |
      | ✨ alice       |  |
