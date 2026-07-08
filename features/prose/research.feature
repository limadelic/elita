@research
Feature: Research tree

  Scenario: Research synthesizes multiple researchers
    * > el
    * el> get me a research agent
    * el> ask research what makes a city good for remote work
    * verify
      | 🤔 research → researcher_1 | infrastructure and connectivity |
      | ✨ researcher_1             | 100 mbps                        |
      | 🤔 research → researcher_2 | cost of living                  |
      | ✨ researcher_2             | affordable housing              |
      | 🤔 research → researcher_3 | coworking spaces                |
      | ✨ researcher_3             | coworking                       |
      | ✨ research                 | three interconnected dimensions |
