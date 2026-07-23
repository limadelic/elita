@tape:diagnose
Feature: Doctor

  Scenario: speck reads, writes, and runs doctor scenarios
    * > el speck

    * speck> exec doctor

    * speck> log
      | 🧪 doctor_spec       | Ask Tool The Ask tool allows sync messages                          |
      | 🤖 doctor            | Medical doctor who diagnoses patients through questioning           |
      | 🤖 patient           | Patient seeking medical diagnosis                                   |
      | 🎭 speck as tplan    |                                                                     |
      | ✏️ test_scenario     | Synchronous Communication: Doctor asks patient one symptom question |
      | 🎭 speck as texec    |                                                                     |
      | 🚀 doctor_v1         | as doctor                                                           |
      | 🚀 patient_v1        | as patient                                                          |
      | 🤔 speck → doctor_v1 | Please diagnose patient_v1 by asking one question                   |
      | ✨ doctor_v1 → speck  | DIAGNOSIS: Cauda Equina Syndrome                                    |
      | ✨ speck              | Verdict: PASSED                                                     |
      | ✨ speck              | PASSED                                                              |
