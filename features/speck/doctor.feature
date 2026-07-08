@speckdoctor
Feature: Speck doctor

  Scenario: Speck verifies doctor meets its spec
    * > el speck
    * speck> exec doctor
    * verify
      | 📢 speck → doctor_v1 | please diagnose patient_v1 |
      | 🤔 doctor_v1 → patient_v1 | what is your main complaint |
      | ✨ patient_v1 | wah! wah! |
      | ✨ doctor_v1 | infantile colic |
      | ✨ speck | validated |
