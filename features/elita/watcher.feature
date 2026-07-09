Feature: Clockwatcher

  Scenario Outline: Watcher responds based on business hours
    * > el clockwatcher

    * clockwatcher> file a report
      | 🤔 el → clockwatcher | file a report   |
      | ✨ clockwatcher       | <response>      |

    Examples: Morning
      | cassette | clock  | response              |
      | dawn     | 06:00  | Not yet available     |

    Examples: Noon
      | cassette | clock  | response           |
      | noon     | 12:00  | I'm done for the day |

    Examples: Evening
      | cassette | clock  | response           |
      | night    | 20:00  | Business hours over |
