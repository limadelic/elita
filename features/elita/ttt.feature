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
      | 📢 el → bob    | Alice says     |
      | 📢 bob → Alice | Nice opening   |
      | 📢 alice → bob | Good move      |
