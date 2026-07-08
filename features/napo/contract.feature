Feature: Napo contract

  Scenario: Napo reviews a contract across facets
    * > el
    * el> get me a napo agent
    * el> ask napo to review an employment contract that pays no overtime, has a 2 year non-compete, claims all personal projects as company property and forces arbitration at the employee's expense
    * verify
      | 🤔 el → napo                   | review an employment contract                     |
      | 🤔 napo → contract_lead        | Evaluate this employment contract comprehensively |
      | 📢 contract_lead → overtime    | No overtime pay clause                            |
      | 📢 contract_lead → noncompete  | 2-year non-compete clause                         |
      | 📢 contract_lead → ipassign    | Claims all personal projects as company property  |
      | 📢 contract_lead → arbitration | Forced arbitration at employee's expense          |
      | ✨ contract_lead                | spawned four specialized analysis agents          |
      | ✨ el                           | red flags across all four                         |
