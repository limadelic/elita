@napocontract
Feature: Napo contract

  Scenario: Napo reviews a contract across facets
    * > el
    * el> get me a napo agent
    * el> ask napo to review an employment contract that pays no overtime, has a 2 year non-compete, claims all personal projects as company property and forces arbitration at the employee's expense
    * verify
      | 🤔 el → napo | review an employment contract |
      | 🚀 contract_lead | orchestration |
      | 📢 contract_lead → overtime | no overtime pay |
      | 📢 contract_lead → noncompete | non-compete |
      | 📢 contract_lead → ipassign | personal projects |
      | 📢 contract_lead → arbitration | arbitration |
      | ✨ contract_lead | spawned four specialized |
      | ✨ napo | red flags |
      | ✨ napo | Do not sign as-is |
      | ✨ el | Don't sign as-is |
