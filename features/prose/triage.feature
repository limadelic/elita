Feature: Inbox triage

  Scenario: Triage sorts the inbox
    * > el triage

    * triage> email 1 says urgent payment overdue, your billing is past due. email 2 says claim your free prize, you have won a promotional offer. email 3 says new feature request, please add dark mode to the app
      | 🤔 triage → classifier_1 | urgent payment overdue                            |
      | ✨ classifier_1           | urgent                                            |
      | 🤔 triage → classifier_2 | claim your free prize                             |
      | ✨ classifier_2           | spam                                              |
      | 🤔 triage → classifier_3 | dark mode                                         |
      | ✨ classifier_3           | feature                                           |
      | ✨ triage                 | urgent (billing), spam (promo), feature (request) |
