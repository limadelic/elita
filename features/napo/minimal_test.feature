@wip
@tape:contract
Feature: Minimal test to see transcript

  Scenario: Employment minimal
    * > el
    * el> get me a napo agent
    * el> ask napo to review an employment contract that pays no overtime
      | nonexistent_prefix | nonexistent text that should fail |
    * print transcript
