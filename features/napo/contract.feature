Feature: Napo contract

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

    Examples: Vendor agreement
      | cassette | type   | problem                                                                                                                                  | a1      | aspect_1                     | a2      | aspect_2                        | a3        | aspect_3                                | a4    | aspect_4                         | finding_1                               | finding_2                        | finding_3                       | finding_4                         |
      | vendor   | vendor | a vendor agreement with unilateral pricing increases, auto-renewal trap, one-sided liability, and vendor-favorable indemnification terms | pricing | Unilateral pricing increases | renewal | Auto-renewal with 60-day notice | liability | One-sided liability cap favoring vendor | indem | Vendor-favorable indemnification | Vendor can increase prices without caps | Auto-renewal defaults to renewal | Liability caps are asymmetrical | You indemnify vendor unilaterally |

    Examples: Office lease
      | cassette | type         | problem                                                                                                              | a1         | aspect_1               | a2        | aspect_2                  | a3         | aspect_3                     | a4      | aspect_4           | finding_1                        | finding_2                      | finding_3                           | finding_4                           |
      | lease    | office lease | an office lease with triple-net costs, personal guarantee, landlord early termination rights, and no renewal options | triple_net | Triple-net costs (NNN) | guarantee | Personal guarantee clause | early_term | Landlord can terminate early | renewal | No renewal options | CAM escalation hides $300K-$600K | Personal guarantee $1.75M risk | Landlord can terminate unilaterally | No renewal option forces relocation |
