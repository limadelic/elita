Feature: Birth

  @wip
  Scenario: Mother gives birth to a baby
    * > el

    * el> get me a mother ready to give birth
      | 📢 el → mother | ready to give birth |

    * el> tell the mother it's time
      | 📢 el → mother | It's time                     |
      | ✨ mother       | my beautiful baby has arrived |

    * el> ask the baby how does it feel to be born
      | 📢 el → baby | just born        |
      | 🤔 el → baby | How does it feel |
      | ✨ baby       | WAAHHHHH         |
