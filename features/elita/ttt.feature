Feature: Ttt

  Scenario: Two players play to a tie
    * > el

    * el> get me two ttt players named alice and bob
      | 📢 el → alice | You are Alice |
      | 📢 el → bob   | You are Bob   |

    * el> tell alice start a game with bob, you are X, play first
      | 📢 alice → bob | I'll take the center       |
      |                | _ \| _ \| _                |
      |                | _ \| X \| _                |
      |                | _ \| _ \| _                |
      | 📢 bob → alice | I'll take the top-left     |
      |                | O \| _ \| _                |
      |                | _ \| X \| _                |
      |                | _ \| _ \| _                |
      | 📢 alice → bob | I'll take the bottom-right |
      |                | O \| _ \| _                |
      |                | _ \| X \| _                |
      |                | _ \| _ \| X                |
      | 📢 bob → alice | I'll take the top-right    |
      |                | O \| _ \| O                |
      |                | _ \| X \| _                |
      |                | _ \| _ \| X                |
      | 📢 alice → bob | I'll take the top-middle   |
      |                | O \| X \| O                |
      |                | _ \| X \| _                |
      |                | _ \| _ \| X                |
      | 📢 bob → alice | I'll block the bottom      |
      |                | O \| X \| O                |
      |                | _ \| X \| _                |
      |                | _ \| O \| X                |
      | 📢 alice → bob | I'll take the middle-left  |
      |                | O \| X \| O                |
      |                | X \| X \| _                |
      |                | _ \| O \| X                |
      | 📢 bob → alice | I'll take the middle-right |
      |                | O \| X \| O                |
      |                | X \| X \| O                |
      |                | _ \| O \| X                |
      | 📢 alice → bob | I'll take the bottom-left  |
      |                | O \| X \| O                |
      |                | X \| X \| O                |
      |                | X \| O \| X                |

    * el> ask alice did the game finish and was it a win or a tie
      | ✨ el | Game Over - Tie |
