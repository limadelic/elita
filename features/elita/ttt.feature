Feature: Ttt

  Scenario: Two players play to a tie
    * > el

    * el> get me two ttt players named alice and bob
      | 📢 el → alice | You are Alice, a ttt player |
      | 📢 el → bob   | You are Bob, a ttt player   |

    * el> tell alice start a game with bob, you are X, play first
      | 📢 alice → bob | I'll take square 5       |
      |                | _ \| _ \| _            |
      |                | _ \| X \| _            |
      |                | _ \| _ \| _            |

      | 📢 bob → Alice | I'll take square 1       |
      |                | O \| _ \| _            |
      |                | _ \| X \| _            |
      |                | _ \| _ \| _            |

      | 📢 alice → bob | I'll take square 9       |
      |                | O \| _ \| _            |
      |                | _ \| X \| _            |
      |                | _ \| _ \| X            |

      | 📢 bob → Alice | I'll take square 3       |
      |                | O \| _ \| O            |
      |                | _ \| X \| _            |
      |                | _ \| _ \| X            |

      | 📢 alice → bob | I'll take square 7       |
      |                | O \| _ \| O            |
      |                | _ \| X \| _            |
      |                | X \| _ \| X            |

      | 📢 bob → Alice | I'll take square 8       |
      |                | O \| _ \| O            |
      |                | _ \| X \| _            |
      |                | X \| O \| X            |

      | 📢 alice → bob | I'll take square 4       |
      |                | O \| _ \| O            |
      |                | X \| X \| _            |
      |                | X \| O \| X            |

      | 📢 bob → Alice | I'll take square 6       |
      |                | O \| _ \| O            |
      |                | X \| X \| O            |
      |                | X \| O \| X            |

      | 📢 alice → bob | I'll take square 2       |
      |                | O \| X \| O            |
      |                | X \| X \| O            |
      |                | X \| O \| X            |

      | ✨ alice        | Game Over - Tie          |
