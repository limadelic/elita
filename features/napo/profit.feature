@napoprofit
Feature: Napo profit

  Scenario: Napo splits a conglomerate decline by division
    * > el
    * el> get me a napo agent
    * el> ask napo - our conglomerate profit declined 30% across grocery retail, streaming media and industrial logistics, build the complete root-cause tree for each division
    * verify
      | 🤔 el → napo | root-cause tree |
      | 🤔 napo → judge | root-cause |
      | ✨ judge | no |
      | 📢 napo → grocery | grocery |
      | 📢 napo → stream | streaming |
      | 📢 napo → logistics | logistics |
      | ✨ napo | split phase |
      | ✨ el | awaiting |
