@tape:diagnose
Feature: Doctor

  Scenario: speck reads, writes, and runs doctor scenarios
    * > el speck

    * speck> exec doctor

    * speck> log
      | 🧪 doctor_spec            | Ask Tool The Ask tool allows sync messages                              |
      | 🤖 doctor                 | Medical doctor who diagnoses patients through questioning               |
      | 🤖 actor                  | Versatile actor who plays any role convincingly with improvisation      |
      | 🤔 doctor_v1 → patient_v1 | What is your main complaint or symptom that brought you to see me today |
      | ✨ patient_v1 → doctor_v1  | *cries loudly* WAH! WAH! WAHHHHH!                                       |
      | 🎭 speck as tplan         |                                                                         |
      | 🎭 speck as texec         |                                                                         |
      | 🚀 doctor_v1              | as doctor                                                               |
      | 🚀 patient_v1             | as baby                                                                 |
      | ✨ doctor_v1 → speck       | Infantile Colic / Normal Neonatal Behavior                              |
      | ✨ speck                   | Verdict: PASSED                                                         |
      | ✨ speck                   | PASSED                                                                  |
