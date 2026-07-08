Feature: Ttt

  Scenario: Two players play to the end
    * > el

    * el> get me two ttt players named alice and bob

    * el> tell alice start a game with bob, you are X, play first
      | 📢 el → bob    | Alice says: Let's play! I'll be X. Here's my opening move: X \| _ \| _     |
      | 📢 bob → Alice | Nice opening! I'll take the center                                         |
      | 📢 alice → bob | Good move! I'll take the bottom-right corner: X \| _ \| _                  |
      | 📢 bob → Alice | I'll block your diagonal                                                   |
      | 📢 alice → bob | Good block! I'll take the top-right to set up my winning move: X \| _ \| X |
      | 📢 bob → Alice | I've got to block your top row! X \| O \| X                                |
      | 📢 alice → bob | I'll take the top-middle and win! X \| X \| X                              |
      | ✨ alice        | Game Over - Alice Wins                                                     |
