Feature: Ttt

  @tape:ttt
  Scenario: Two players play to the end
    * > el ttt as alice

    * > el ttt as bob

    * bob> alice is gonna be your opponent, wait for her move
      | ready to play |

    * alice> start a game with bob, you are X, play first
      | game started |

    * alice> log
      | 📢 alice → bob | Hey! Let's play tic-tac-toe. I'm X and I'll go first. |
      |                | _ \| _ \| _                                           |
      |                | _ \| X \| _                                           |
      |                | _ \| _ \| _                                           |

    * bob> log
      | 📢 bob → alice | Nice opening! I'll take a corner (position 1). |
      |                | O \| _ \| _                                    |
      |                | _ \| X \| _                                    |
      |                | _ \| _ \| _                                    |

    * alice> log
      | 📢 alice → bob | Good move! I'll take the opposite corner (position 9) to balance. |
      |                | O \| _ \| _                                                       |
      |                | _ \| X \| _                                                       |
      |                | _ \| _ \| X                                                       |

    * bob> log
      | 📢 bob → alice | Smart! I'll take position 3 to block your potential diagonal and keep my options open. |
      |                | O \| _ \| O                                                                            |
      |                | _ \| X \| _                                                                            |
      |                | _ \| _ \| X                                                                            |

    * alice> log
      | 📢 alice → bob | I'll take position 7 to block your diagonal and create my own threat. |
      |                | O \| _ \| O                                                           |
      |                | _ \| X \| _                                                           |
      |                | X \| _ \| X                                                           |

    * bob> log
      | 📢 bob → alice | Gotta block! You've got X's on 7 and 9, so I'm taking position 8 to stop your bottom row win. |
      |                | O \| _ \| O                                                                                   |
      |                | _ \| X \| _                                                                                   |
      |                | X \| O \| X                                                                                   |

    * alice> log
      | 📢 alice → bob | I'll take position 4 to block your potential left column (you'd have 1, 3, and threatening more). |
      |                | O \| _ \| O                                                                                       |
      |                | X \| X \| _                                                                                       |
      |                | X \| O \| X                                                                                       |

    * bob> log
      | 📢 bob → alice | I'll take position 6 to block your middle row (you've got X's on positions 4 and 5). |
      |                | O \| _ \| O                                                                          |
      |                | X \| X \| O                                                                          |
      |                | X \| O \| X                                                                          |

    * alice> log
      | 📢 alice → bob | I'll take position 2, the last remaining spot. |
      |                | O \| X \| O                                    |
      |                | X \| X \| O                                    |
      |                | X \| O \| X                                    |
      |                | It's a tie! Good game, Bob!                    |
