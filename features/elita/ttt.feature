Feature: Ttt

  Scenario: Two players play to the end
    * > el

    * el> get me two ttt players named alice and bob
      | 📢 el → alice | You are Alice, a ttt player |
      | 📢 el → bob   | You are Bob, a ttt player   |

    * el> tell alice start a game with bob, you are X, play first
      | 📢 el → bob    | Alice says: Let's play! I'll be X.       |
      |                | X \| _ \| _                              |
      |                | _ \| _ \| _                              |
      |                | _ \| _ \| _                              |
      | 📢 bob → Alice | Nice opening! I'll take the center:      |
      |                | X \| _ \| _                              |
      |                | _ \| O \| _                              |
      |                | _ \| _ \| _                              |
      | 📢 alice → bob | Good move! I'll take the bottom-right    |
      |                | X \| _ \| _                              |
      |                | _ \| O \| _                              |
      |                | _ \| _ \| X                              |
      | 📢 bob → Alice | Alright! I'll block your diagonal threat |
      |                | X \| _ \| _                              |
      |                | _ \| O \| _                              |
      |                | O \| _ \| X                              |
      | 📢 alice → bob | Good block! I'll take the top-right      |
      |                | X \| _ \| X                              |
      |                | _ \| O \| _                              |
      |                | X \| _ \| O                              |
      | 📢 bob → Alice | I've got to block your top row!          |
      |                | X \| O \| X                              |
      |                | _ \| O \| _                              |
      |                | X \| _ \| O                              |
      | 📢 alice → bob | I'll take the top-middle and win!        |
      |                | X \| X \| X                              |
      |                | _ \| O \| _                              |
      |                | O \| _ \| X                              |
      | ✨ alice        | Game Over - Alice Wins                   |
