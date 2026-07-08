@napoprofit
Feature: Napo profit

  Scenario: Napo splits a conglomerate decline by division
    * > el
    * el> get me a napo agent
    * el> ask napo - our conglomerate profit declined 30% across grocery retail, streaming media and industrial logistics, build the complete root-cause tree for each division
    * verify
      | 🤔 el → napo | root-cause tree for each division |
      | 🤔 napo → judge | root-cause tree |
      | ✨ judge | no. |
      | ✏️ depth_grocery | 1 |
      | 📢 napo → grocery | grocery retail division |
      | 📢 napo → stream | streaming media division |
      | 📢 napo → logistics | industrial logistics division |
      | ✨ napo | split phase complete |
      | ✨ el | awaiting completion |
