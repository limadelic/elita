@watch
Feature: Clockwatcher

  Scenario: Watcher only works business hours
    * > el
    * el> get me a clockwatcher
    * el> ask the clockwatcher to file a report:
      | no start |
