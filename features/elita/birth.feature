Feature: Birth

  Scenario: Mother gives birth to a baby
    * > el mother

    * mother> it's time to give birth
      | the baby has arrived |
      | congratulations      |

    * mother> log
      | 🚀 baby | spawn |

    * baby> spank
      | WAAAAAHHHHHHH |
      | wailing       |
