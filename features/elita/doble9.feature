Feature: Doble9

  Scenario: A fresh game deals ten dominoes to each player
    * > el

    * el> get me a doble9 game and four greed players named top, left, bottom and right

    * el> ask doble9 to start a new game with top, left, bottom and right
      | 🤔 el → game     | start a new game                        |
      | ✨ game           | Bienvenido                              |
      | 📢 game → top    | 0-0 0-1 0-2 0-3 0-4 0-5 0-6 0-7 0-8 0-9 |
      | 📢 game → left   | 1-1 1-2 1-3 1-4 1-5 1-6 1-7 1-8 1-9 2-2 |
      | 📢 game → bottom | 2-3 2-4 2-5 2-6 2-7 2-8 2-9 3-3 3-4 3-5 |
      | 📢 game → right  | 3-6 3-7 3-8 3-9 4-4 4-5 4-6 4-7 4-8 4-9 |
      | ✨ game           | JUEGO INICIADO                          |
      | ✨ el             | Fichas en mano                          |
