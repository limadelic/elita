@wip
Feature: Greed

  Scenario: Greed picks highest value domino
    * > el greed

    * greed> Table: [3,5], Dominoes: [9,9], [2,3], [9,6], [4,5]
      | [4,5] |

    * greed> Table: [2,5], Dominoes: [1,2], [3,6], [0,4] [7,6]
      | [1,2] |

    * greed> Table: [1,6], Dominoes: [2,3], [5,6]
      | [5,6] |

  Scenario: Greed knocks when no moves
    * > el greed

    * greed> Table: [1,3], Dominoes: [2,4], [5,6], [0,0]
      | knock knock |
