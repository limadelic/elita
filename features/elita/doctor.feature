@doctor
Feature: Doctor

  Scenario: Doctor diagnoses a patient
    * > el
    * el> have an actor play a patient with appendicitis
    * el> ask a doctor to diagnose them
    * verify
      | 📢 el → patient | you are a patient with appendicitis |
      | 🤔 el → doctor | diagnose the patient |
      | 🤔 doctor → patient | main complaint |
      | ✨ patient | pain in my lower right side |
      | 🤔 doctor → patient | fever or chills |
      | ✨ patient | around 101 |
      | ✨ doctor | acute appendicitis |
