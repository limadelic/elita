Feature: Napo profit

  Scenario: Napo splits a conglomerate decline by division
    * > el
    * el> get me a napo agent
    * el> ask napo - our conglomerate profit declined 30% across grocery retail, streaming media and industrial logistics, build the complete root-cause tree for each division
    * verify
      | 📢 napo → grocery   | grocery retail division             |
      | 📢 napo → streaming | streaming media division            |
      | 👀 napo             | (empty)                             |
      | 📢 napo → logistics | industrial logistics division       |
      | 👀 napo             | (empty)                             |
      | 🚀 judge            | spawn                               |
      | 🚀 napo             | spawn                               |
      | ✨ napo              | spawned three specialized analyzers |
