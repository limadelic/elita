@masked
Feature: Masked relay

  Scenario: Relay scouts each aspect blind and builds consensus
    * > el
    * el> get me a relay agent
    * el> ask relay - price is expensive at $99 a month, friction is smooth onboarding, desire is strong customer demand
    * verify
      | 🤔 relay → scout_price | the price is $99 a month |
      | ✨ scout_price | price concerns high |
      | 🤔 relay → scout_friction | the onboarding is smooth |
      | ✨ scout_friction | friction acceptable |
      | 🤔 relay → scout_desire | strong customer demand |
      | ✨ scout_desire | desire strong |
      | 🤔 relay → auditor | synthesize these three verdicts |
      | ✨ auditor | consensus: price-high friction-acceptable desire-strong |
