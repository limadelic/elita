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
      | 📢 el → alice  | bob          |
      | 📢 alice → bob | Hey Bob      |
      | 📢 bob → Alice | Hey Alice    |
      | 📢 alice → bob | Good move    |
      | 📢 bob → Alice | I'll block   |
      | 📢 alice → bob | Smart move   |
      | 📢 bob → Alice | reconsider   |
      | 📢 alice → bob | bottom-left  |
      | 📢 bob → Alice | top-right    |
      | 📢 alice → bob | top-right    |
      | 📢 bob → Alice | block your   |
      | 📢 alice → bob | win          |

    * el> ask alice did the game finish and was it a win or a tie
      | 🤔 el → alice | game finish  |
      | ✨ alice       | win          |
