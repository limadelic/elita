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
      | clock               | cassette     | reply1                              | reply2                                           | reply3                              |
      | 2025-07-07 06:00:00 | early        | 6:00 AM on Monday                   | No, I don't start until 9                        | work hours begin at 9 AM            |
      | 2025-07-07 10:00:00 | clockwatcher | 10:00 AM                            | work hours                                       | 9 AM to 5 PM                        |
      | 2025-07-07 12:30:00 | lunch        | No, it's lunch time                 | 12:30 PM                                         | lunch break runs from 12 PM to 1 PM |
      | 2025-07-07 18:00:00 | late         | 6:00 PM                             | No, I'm done for the day                         | My work hours are 9 AM to 5 PM      |
      | 2025-07-12 10:00:00 | weekend      | 10:00 AM on Saturday, July 12, 2025 | It's Saturday, which is outside my work schedule | Monday through Friday, 9 AM to 5 PM |
