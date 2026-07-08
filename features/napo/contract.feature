@napocontract
Feature: Napo contract

  Scenario: Napo reviews a contract across facets
    * > el
    * el> get me a napo agent
    * el> ask napo to review an employment contract that pays no overtime, has a 2 year non-compete, claims all personal projects as company property and forces arbitration at the employee's expense
    * verify
      | 🤔 el → napo | review an employment contract |
      | 🤔 napo → contract_lead | no overtime pay |
      | 📢 contract_lead → overtime | no overtime pay clause |
      | 📢 contract_lead → noncompete | 2-year non-compete |
      | 📢 contract_lead → ipassign | personal projects |
      | 📢 contract_lead → arbitration | forced arbitration |
      | ✨ el | don't sign as-is |
