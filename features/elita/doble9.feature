@dominoes
Feature: Doble9

  Scenario: A fresh game deals ten dominoes to each player
    * > el
    * el> get me a doble9 game and four greed players named top, left, bottom and right
    * el> ask doble9 to start a new game with top, left, bottom and right
    * verify
      | 🤔 el → game | start a new game |
      | 🛠️ dale_agua | dominoes |
      | 📢 game → right | prepárate para recibir tus fichas |
      | 🛠️ pick_10 | dominoes |
      | 📢 game → bottom | tienes 10 dominoes |
      | ✨ game | juego iniciado |
