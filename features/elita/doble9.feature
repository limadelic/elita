Feature: Doble9

  @tape:doble9
  Scenario: A fresh game deals ten dominoes to each player
    * > el doble9

    * doble9> start a new game with players: top, left, bottom, right
      | ready    |
      | shuffled |

    * doble9> i need 10 dominoes
      | 9      |
      | [1, 4] |
