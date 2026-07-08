Feature: Ttt

  Scenario: Two players play to the end
    * > el

    * el> get me two ttt players named alice and bob
      | 📢 el → alice | You are Alice, a ttt player |
      | 📢 el → bob   | You are Bob, a ttt player   |

    * el> tell alice start a game with bob, you are X, play first
      | 📢 el → bob    | Let's play! I'll be X. Here's my opening move: X \| _ \| _ _ \| _ \| _ _ \| _ \| _ Your turn! You're O.         |
      | 📢 bob → Alice | Nice opening! I'll take the center: X \| _ \| _ _ \| O \| _ _ \| _ \| _ Your move!                              |
      | 📢 alice → bob | Let's go, Bob! I'll take the bottom-right corner: X \| _ \| _ _ \| O \| _ _ \| _ \| X Your turn!                |
      | 📢 bob → Alice | Alright! I'll block your diagonal threat: X \| _ \| _ _ \| O \| _ O \| _ \| X Your move!                        |
      | 📢 alice → bob | Good block! I'll take the top-right to set up my winning move: X \| _ \| X _ \| O \| _ X \| _ \| O Your turn!   |
      | 📢 bob → Alice | I've got to block your top row! X \| O \| X _ \| O \| _ X \| _ \| O Your move!                                  |
      | 📢 alice → bob | I'll take the top-middle and win! X \| X \| X _ \| O \| _ O \| _ \| X **I win!** Three in a row across the top! |
      | ✨ alice        | Game Over - Alice Wins                                                                                          |
