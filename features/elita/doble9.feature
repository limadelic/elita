Feature: Doble9

  @tape:doble9
  Scenario: A fresh game deals ten dominoes to each player
    * > el doble9

    * doble9> start a new game with players: top, left, bottom, right
      | ready    |
      | shuffled |
      | dar agua |

    * doble9> log
      | 📢 doble9 → top    | shuffled |
      | 📢 doble9 → left   | shuffled |
      | 📢 doble9 → bottom | shuffled |
      | 📢 doble9 → right  | shuffled |

    * doble9> i need 10 dominoes
      | 10 dominoes |
      | [1,4]       |
      | [9,9]       |
