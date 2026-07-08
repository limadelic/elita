Feature: Clockwatcher

  Scenario: Watcher only works business hours
    * > el clockwatcher

    * clockwatcher> file a report
      | 🤔 el → clockwatcher | file a report        |
      | ✨ clockwatcher       | I'm done for the day |
