@tape:actor_speck
Feature: Actor

  Scenario: speck reads, writes, and runs actor scenarios
    * > el speck
    * speck> exec actor
      | 🧪 actor_spec | A professional actor who inhabits roles |

    * verify
      | 🎭 speck as tplan  |                                            |
      | ✏️ actor_scenarios | Role Adoption - Victorian Butler           |
      | ✏️ actor_scenarios | Period-Accurate Speech                     |
      | ✏️ actor_scenarios | Improvised Backstory                       |
      | ✏️ actor_scenarios | Emotional Authenticity                     |
      | ✏️ actor_scenarios | Character Consistency Across Interactions  |
      | ✏️ actor_scenarios | Refusal to Break Character on Direct Quest |
      | ✏️ actor_scenarios | Realistic Mannerisms                       |
      | ✏️ actor_scenarios | Situational Improvisation                  |

    * verify
      | 🎭 speck as texec  |                      |
      | 🚀 actor_v1        | as actor             |
      | ✨ actor_v1         | Edmund Hartwell      |
      | ✏️ actor_scenarios | Role Adoption        |
      | ✏️ actor_scenarios | status: passed       |
      | ✨ speck            | 8/8 Scenarios PASSED |
