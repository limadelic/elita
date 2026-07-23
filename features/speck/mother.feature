@tape:mother
Feature: Mother

  Scenario: speck reads, writes, and runs mother scenarios
    * > el speck
    * speck> exec mother
      | Spec: mother                                    |
      | a baby agent is created and becomes operational |
      | can cry                                         |
      | distinct, independent agent                     |
      | triggers the spawn action                       |
      | Verdict: ✓ PASSED                               |
