Feature: Masked relay

  Scenario: Relay scouts each aspect blind and builds consensus
    * > el relay

    * relay> price is expensive at $99 a month, friction is smooth onboarding, desire is strong customer demand
      | 🤔 el → relay      | price is expensive     |
      | ✨ scout_price      | price concerns high    |
      | ✨ scout_friction   | friction acceptable    |
      | ✨ scout_desire     | desire strong          |
      | 🤔 relay → auditor | Synthesize these three |
      | ✨ auditor          | consensus              |
      | ✨ relay            | consensus              |
