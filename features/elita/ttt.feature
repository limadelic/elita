@tictactoe
Feature: Ttt

  Scenario: Two players play to the end
    * > el
    * el> get me two ttt players named alice and bob
    * el> tell bob alice is gonna be your opponent, wait for her move
    * el> tell alice start a game with bob, you are X, play first
    * el> ask alice did the game finish and was it a win or a tie
    * verify
      | 📢 el → bob | alice is gonna be your opponent |
      | 📢 el → alice | start a game with bob |
      | ✨ alice | finished with a win |
