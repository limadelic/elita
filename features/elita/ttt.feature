Feature: Ttt

  Scenario: Two players play to a tie
    * > el

    * el> get me two ttt players named alice and bob
      | 📢 el → alice | You are Alice, a ttt player |
      | 📢 el → bob   | You are Bob, a ttt player   |

    * el> tell alice start a game with bob, you are X, play first
      | 📢 alice → bob | I'll take the center: |
      |                | _ \| _ \| _           |
      |                | _ \| X \| _           |
      |                | _ \| _ \| _           |
