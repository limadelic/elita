Feature: Napo contract

  Scenario: Napo analyzes employment contract
    * > el
    * el> get me a napo agent
      | ✨ el | Done. Napo is ready. |

    * el> ask napo to review an employment contract that pays no overtime, has a 2 year non-compete, claims all personal projects as company property and forces arbitration at the employee's expense
      | ✨ el | Violates FLSA if you're non-exempt           |
      | ✨ el | Enforceability varies by state               |
      | ✨ el | Likely unenforceable if created outside work |
      | ✨ el | Often unenforceable under unconscionability  |

  @wip
  Scenario Outline: Napo analyzes contracts with specialists
    * > el
    * el> get me a napo agent
    * el> ask napo to review <problem>
      | ✨ el | <finding_1> |
      | ✨ el | <finding_2> |
      | ✨ el | <finding_3> |
      | ✨ el | <finding_4> |

    Examples: Vendor agreement
      | cassette | problem                                                                                                                                  | finding_1                               | finding_2                        | finding_3                       | finding_4                         |
      | vendor   | a vendor agreement with unilateral pricing increases, auto-renewal trap, one-sided liability, and vendor-favorable indemnification terms | Vendor can increase prices without caps | Auto-renewal defaults to renewal | Liability caps are asymmetrical | You indemnify vendor unilaterally |

    Examples: Office lease
      | cassette | problem                                                                                                              | finding_1                        | finding_2                      | finding_3                           | finding_4                           |
      | lease    | an office lease with triple-net costs, personal guarantee, landlord early termination rights, and no renewal options | CAM escalation hides $300K-$600K | Personal guarantee $1.75M risk | Landlord can terminate unilaterally | No renewal option forces relocation |
