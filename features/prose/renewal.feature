@renewal
Feature: Renewal risk

  Scenario: Coordinator flags at-risk renewals across accounts
    * > el
    * el> get me a coordinator agent
    * el> ask the coordinator - acme usage dropped 80% with 5 critical tickets, renews in 60 days. globex usage stable with 0 tickets, renews in 180 days. initech usage stable with 3 routine tickets, renews in 35 days
      | acme    |
      | globex  |
      | initech |
      | risk    |
