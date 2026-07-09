Feature: Napo contract

  @tape:vendor
  Scenario: Napo analyzes vendor agreement
    * > el
    * el> get me a napo agent
    * el> ask napo to review a vendor agreement with unilateral pricing increases, auto-renewal trap, one-sided liability, and vendor-favorable indemnification terms

  @tape:lease
  Scenario: Napo analyzes office lease
    * > el
    * el> get me a napo agent
    * el> ask napo to review an office lease with triple-net costs, personal guarantee, landlord early termination rights, and no renewal options

  Scenario Outline: Napo analyzes contracts, split across specialist agents
    * > el

    * el> get me a napo agent

    * el> ask napo to review <problem>
      | 🤔 el → napo            | review <problem>                         |
      | 🤔 napo → contract_lead | Evaluate this <type> contract            |
      | 📢 contract_lead → <a1> | <aspect_1>                               |
      | 📢 contract_lead → <a2> | <aspect_2>                               |
      | 📢 contract_lead → <a3> | <aspect_3>                               |
      | 📢 contract_lead → <a4> | <aspect_4>                               |
      | ✨ contract_lead         | spawned four specialized analysis agents |
      | ✨ el                    | <finding_1>                              |
      | ✨ el                    | <finding_2>                              |
      | ✨ el                    | <finding_3>                              |
      | ✨ el                    | <finding_4>                              |

    Examples: Employment contract
      | cassette | type       | problem                                                                                                                                                                   | a1       | aspect_1               | a2         | aspect_2                  | a3       | aspect_3                                         | a4          | aspect_4                                 | finding_1                          | finding_2                      | finding_3                                    | finding_4                                   |
      | contract | employment | an employment contract that pays no overtime, has a 2 year non-compete, claims all personal projects as company property and forces arbitration at the employee's expense | overtime | No overtime pay clause | noncompete | 2-year non-compete clause | ipassign | Claims all personal projects as company property | arbitration | Forced arbitration at employee's expense | Violates FLSA if you're non-exempt | Enforceability varies by state | Likely unenforceable if created outside work | Often unenforceable under unconscionability |
