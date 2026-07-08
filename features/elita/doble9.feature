Feature: Doble9

  Scenario: A fresh game deals ten dominoes to each player
    * > el

    * el> get me a doble9 game and four greed players named top, left, bottom and right

    * el> ask doble9 to start a new game with top, left, bottom and right
      | 🤔 el → game     | start a new game  |
      | ✨ game           | Bienvenido        |
      | 📢 game → top    | FICHAS REPARTIDAS |
      | 📢 game → left   | FICHAS REPARTIDAS |
      | 📢 game → bottom | FICHAS REPARTIDAS |
      | 📢 game → right  | FICHAS REPARTIDAS |
      | ✨ game           | JUEGO INICIADO    |
      | ✨ el             | Fichas en mano    |
