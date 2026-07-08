Feature: Ttt

  Scenario: Two players play to the end
    * > el

    * el> get me two ttt players named alice and bob
      | 📢 el → alice | You are Alice, a ttt player |
      | 📢 el → bob   | You are Bob, a ttt player   |

    * el> tell alice start a game with bob, you are X, play first
      | 📢 el → bob    | X \| _ \| _ _ \| _ \| _ _ \| _ \| _ |
      | 📢 bob → Alice | X \| _ \| _ _ \| O \| _ _ \| _ \| _ |
      | 📢 alice → bob | X \| _ \| _ _ \| O \| _ _ \| _ \| X |
      | 📢 bob → Alice | X \| _ \| _ _ \| O \| _ O \| _ \| X |
      | 📢 alice → bob | X \| _ \| X _ \| O \| _ X \| _ \| O |
      | 📢 bob → Alice | X \| O \| X _ \| O \| _ X \| _ \| O |
      | 📢 alice → bob | X \| X \| X _ \| O \| _ O \| _ \| X |
      | ✨ alice        | Game Over - Alice Wins              |
