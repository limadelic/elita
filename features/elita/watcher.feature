Feature: Clockwatcher

  @tape:dawn
  Scenario: Watcher declines before hours
    * > el clockwatcher

    * clockwatcher> file a report
      | 🤔 el → clockwatcher | file a report   |
      | ✨ clockwatcher       | I don't start   |

  @tape:noon
  Scenario: Watcher takes lunch break
    * > el clockwatcher

    * clockwatcher> file a report
      | 🤔 el → clockwatcher | file a report    |
      | ✨ clockwatcher       | it's lunch time  |

  @tape:night
  Scenario: Watcher clocks out after hours
    * > el clockwatcher

    * clockwatcher> file a report
      | 🤔 el → clockwatcher | file a report      |
      | ✨ clockwatcher       | I'm done for the day |
