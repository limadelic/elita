Feature: Clockwatcher

  @tape:clockwatcher
  Scenario: Watcher tells time and work hours
    * > el clockwatcher

    * clockwatcher> can you handle this task?
      | 10:00 AM     |
      | work hours   |
      | 9 AM to 5 PM |
