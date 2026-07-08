@triage
Feature: Inbox triage

  Scenario: Triage sorts the inbox
    * > el
    * el> get me a triage agent
    * el> ask triage - email 1 says urgent payment overdue, your billing is past due. email 2 says claim your free prize, you have won a promotional offer. email 3 says new feature request, please add dark mode to the app
      | urgent  |
      | spam    |
      | feature |
