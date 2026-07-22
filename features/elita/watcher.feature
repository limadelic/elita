Feature: Clockwatcher

  Scenario Outline: Watcher tells time and work hours
    * clock <clock>
    * cassette <cassette>
    * > el clockwatcher as <name>

    * <name>> can you handle this task?
      | <reply1> |
      | <reply2> |
      | <reply3> |

    Examples:
      | name    | clock               | cassette | reply1            | reply2                       | reply3           |
      | early   | 2025-07-07 06:00:00 | early    | 6:00 AM on Monday | No, I don't start until 9 AM | 9 AM to 5 PM     |
      | work    | 2025-07-07 10:00:00 | work     | 10 AM on a Monday | Yes, I can help              | 9 AM to 5 PM     |
      | lunch   | 2025-07-07 12:30:00 | lunch    | 12:30 PM          | no, it's lunch time          | 12 PM to 1 PM    |
      | late    | 2025-07-07 18:00:00 | late     | 6:00 PM           | No, I'm done for the day     | 9 AM to 5 PM     |
      | weekend | 2025-07-12 10:00:00 | weekend  | Saturday          | No, come back Monday         | Monday to Friday |
