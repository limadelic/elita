@tape:tape_miss
Feature: Tape Miss Policy

  Scenario: Tape replays cached responses with default raise on miss
    * > el greet
    * greet> hello
      | ✨ greet | hello from tape |

  @tape:tape_miss_live @tape_on_miss:live
  Scenario: Tape falls through to live on miss
    * > el greet
    * greet> hello
      | ✨ greet | hello from tape |
    * greet> goodbye
      | ✨ greet | stubbed |
