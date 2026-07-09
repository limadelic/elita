@tape:speckdoctor
Feature: Doctor

  Scenario: speck reads, writes, and runs doctor scenarios
    * > el speck
    * speck> exec doctor
      | 🧪 doctor_spec            | ask tool        |
      | 🤖 doctor                 | ask tool        |
      | 🎭 speck as tplan         |                 |
      | ✏️ scenario_1             | Doctor asks one question and waits     |
      | 🎭 speck as texec         |                 |
      | 🚀 doctor_v1              | as doctor       |
      | 🚀 patient_v1             | as baby         |
      | 🤔 doctor_v1 → patient_v1 | main complaint  |
      | ✨ patient_v1              | WAH WAH         |
      | ✨ doctor_v1               | Infantile Colic |
      | ✨ speck                   | PASSED          |
