Feature: Napo profit

  Scenario: Napo splits a conglomerate decline by division
    * > el
    * el> get me a napo agent
    * el> ask napo - our conglomerate profit declined 30% across grocery retail, streaming media and industrial logistics, build the complete root-cause tree for each division
    * verify
      | 🤔 el → napo        | build the complete root-cause tree for each division |
      | ✨ napo              | orchestrator                                         |
      | 🤔 napo → judge     | complete root-cause tree                             |
      | ✨ judge             | No                                                   |
      | 📢 napo → grocery   | demand compression, margin erosion, operational drag |
      | 📢 napo → stream    | subscriber churn, revenue headwinds, cost overruns  |
      | 📢 napo → logistics | volume decline, asset utilization, operational cost  |
      | ✨ napo              | children spawned and told. awaiting completion       |
      | ✨ el                | collecting their root-cause analyses                 |
