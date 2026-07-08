@napoprofit
Feature: Napo profit

  Scenario: Napo splits a conglomerate decline by division
    * > el
    * el> get me a napo agent
    * el> ask napo - our conglomerate profit declined 30% across grocery retail, streaming media and industrial logistics, build the complete root-cause tree for each division
    * verify
      | 🤔 el → napo | root-cause tree |
      | ✨ napo | orchestrator |
      | 🤔 napo → judge | root-cause |
      | ✨ judge | No |
      | 📢 napo → grocery | grocery |
      | 📢 napo → stream | stream |
      | 📢 napo → logistics | logistics |
      | ✨ napo | Split Phase Complete |
      | ✨ el | Listen Phase |
