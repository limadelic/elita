Feature: Ttt

  @wip
  @tape:ttt
  Scenario: Alice and Bob play to completion
    # BLOCKER: Feature framework cannot express multi-agent spawning
    # Cassette records alice and bob as separate agents with direct interactions
    # El REPL doesn't support "tell alice ..." syntax - it treats "tell" as agent name
    # Need: Either el> tell alice <msg> command support, or multi-agent spawn syntax
    * > el

    * el> tell bob alice is gonna be your opponent, wait for her move

    * el> tell alice start a game with bob, you are X, play first

    * el> ask alice tell me: did the game finish and was it a win or tie?
      | game finished |
      | diagonal      |
