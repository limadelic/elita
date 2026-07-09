Feature: Clockwatcher

  Scenario Outline: Watcher responds based on time
    * > el clockwatcher

    * clockwatcher> file a report
      | 🤔 el → clockwatcher | file a report |
      | ✨ clockwatcher       | <response>    |

    Examples: Morning
      | cassette | clock  | response       |
      | dawn     | 06:00  | am start       |

    Examples: Noon
      | cassette | clock  | response       |
      | noon     | 12:00  | midday working |

    Examples: Evening
      | cassette | clock  | response       |
      | night    | 20:00  | hours over     |
