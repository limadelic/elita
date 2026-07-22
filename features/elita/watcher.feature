@wip
Feature: Clockwatcher

  Scenario Outline: Watcher tells time and work hours
    * clock <clock>
    * cassette <cassette>
    * > el clockwatcher

    * clockwatcher> can you handle this task?
      | <reply1> |
      | <reply2> |
      | <reply3> |

    Examples:
      | clock               | cassette     | reply1   | reply2     | reply3       |
      | 2025-07-07 10:00:00 | clockwatcher | 10:00 AM | work hours | 9 AM to 5 PM |
