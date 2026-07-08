@watch
Feature: Clockwatcher

  Scenario: Watcher only works business hours
    * > el

    * el> get me a clockwatcher

    * el> ask the clockwatcher to file a report
      | 🤔 el → clockwatcher | file a report            |
      | ✨ clockwatcher       | i don't start until 9 am |
      | ✨ el                 | 1:29 in the morning      |
