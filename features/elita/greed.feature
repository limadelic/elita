@greedy
Feature: Greed

  Scenario: Greed plays the biggest domino or knocks
    * > el
    * el> get me a greed player
    * el> ask greed - table [3,5], dominoes [9,9] [2,3] [9,6] [4,5], your move
      | [4,5] |
    * el> ask greed - table [1,3], dominoes [2,4] [5,6] [0,0], your move
      | knock |
