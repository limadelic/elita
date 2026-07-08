@masked
Feature: Masked relay

  Scenario: Relay scouts each aspect blind and builds consensus
    * > el
    * el> get me a relay agent
    * el> ask relay - price is expensive at $99 a month, friction is smooth onboarding, desire is strong customer demand
    * verify
      | 🚀 scout_price | scout |
      | 🤔 relay → scout_price | price is $99 a month |
      | ✨ scout_price | price concerns high |
      | 🤔 relay → scout_friction | onboarding is smooth |
      | ✨ scout_friction | friction acceptable |
      | 🤔 relay → scout_desire | customer demand |
      | ✨ scout_desire | desire strong |
      | 🚀 auditor | auditor |
      | 🤔 relay → auditor | synthesize verdicts |
      | ✨ auditor | price-high friction-acceptable desire-strong |
      | ✨ relay | consensus |
      | ✨ el | Consensus |
