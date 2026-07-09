Feature: Clockwatcher

  @tape:dawn
  Scenario: Watcher responds before work hours (dawn)
    * > el clockwatcher

    * clockwatcher> file a report
      | 🤔 el → clockwatcher | file a report         |
      | ✨ clockwatcher       | I don't start until 9 |

  @tape:noon
  Scenario: Watcher responds during lunch (noon)
    * > el clockwatcher

    * clockwatcher> file a report
      | 🤔 el → clockwatcher | file a report         |
      | ✨ clockwatcher       | I don't start until 9 |

  @tape:night
  Scenario: Watcher responds after hours (night)
    * > el clockwatcher

    * clockwatcher> file a report
      | 🤔 el → clockwatcher | file a report         |
      | ✨ clockwatcher       | I don't start until 9 |
