Feature: Birth

  Scenario: Mother gives birth to a baby
    * > el mother

    * mother> it's time to give birth
      | arrived | spawned |

    * mother> log
      | 🚀 baby | spawn |

    * baby> spank
      | cry |
