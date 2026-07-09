Feature: Clockwatcher

  Scenario Outline: Watcher responds by time of day
    * > el clockwatcher

    * clockwatcher> file a report
      | 🤔 el → clockwatcher | file a report       |
      | ✨ clockwatcher       | I don't start until 9 |

    Examples:
      | cassette | clock  |
      | dawn     | 06:00  |
      | noon     | 12:00  |
      | night    | 20:00  |
