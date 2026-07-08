Feature: Ttt

  Scenario: Two players play to the end
    * > el

    * el> get me two ttt players named alice and bob

    * el> tell alice start a game with bob, you are X, play first
      | 📢 alice → bob | I'm X |
      | 📢 bob → Alice | I'll take the center |
      | 📢 alice → bob | I'll take the bottom-right corner |
      | 📢 bob → Alice | I'll block your diagonal |
      | 📢 alice → bob | I'll take the top-right |
      | 📢 bob → Alice | I've got to block your top row |
      | 📢 alice → bob | I'll take the top-middle and win |
      | ✨ alice | Game Over - Alice Wins |
