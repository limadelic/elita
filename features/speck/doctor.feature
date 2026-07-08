@tape:speckdoctor
Feature: Doctor

  Scenario: Doctor diagnoses a patient
    * > el speck
    * speck> exec doctor
    * verify
      | 📢 speck → doctor_v1      | diagnose patient_v1 |
      | 🤔 doctor_v1 → patient_v1 | main complaint      |
      | ✨ patient_v1              | WAH! WAH!           |
      | 🤔 doctor_v1 → patient_v1 | how long            |
      | ✨ doctor_v1               | Infantile Colic     |
      | 🤔 speck → doctor_v1      | ask tool            |
      | ✨ doctor_v1               | did block           |
      | ✨ speck                   | PASSED              |
