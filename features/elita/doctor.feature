@doctor
Feature: Doctor

  Scenario: Doctor diagnoses a patient
    * > el
    * el> have an actor play a patient with appendicitis
    * el> ask a doctor to diagnose them
    * verify
      | 📢 el → patient | patient with appendicitis |
      | 🤔 el → doctor | diagnose the patient |
      | 🤔 doctor → patient | main complaint |
      | ✨ patient | lower right side |
      | 🤔 doctor → patient | fever or chills |
      | ✨ patient | around 101 |
      | 🤔 doctor → patient | bowel movements |
      | ✨ doctor | ACUTE APPENDICITIS |
      | ✨ el | You will need surgery |
