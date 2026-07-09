Feature: Clockwatcher

  Scenario: Watcher works outside business hours
    * > el clockwatcher

    * clockwatcher> file a report
      | 🤔 el → clockwatcher | file a report              |
      | ✨ clockwatcher       | No, I don't start until   |
