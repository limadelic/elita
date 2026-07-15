@tape:speckdoctor
Feature: Doctor

  @wip
  Scenario: speck reads, writes, and runs doctor scenarios
    * > el speck
    * speck> exec doctor
      | 🧪 doctor_spec | ask tool |
    * verify
      | 🎭 speck as tplan |                                    |
      | ✏️ scenario_1     | Doctor asks one question and waits |
      | ✏️ scenario_2     | Doctor makes diagnosis             |
      | ✏️ scenario_3     | Synchronous communication          |
    * verify
      | 🎭 speck as texec         |                 |
      | 🚀 doctor_v1              | as doctor       |
      | 🚀 patient_v1             | as baby         |
      | 🤔 doctor_v1 → patient_v1 | main complaint  |
      | ✨ patient_v1              | WAH WAH         |
      | ✨ doctor_v1               | Infantile Colic |
      | ✨ speck                   | PASSED          |
