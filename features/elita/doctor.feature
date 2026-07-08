@doctor
Feature: Doctor

  Scenario: Doctor diagnoses a patient
    * > el
    * el> have an actor play a patient with appendicitis
    * el> ask a doctor to diagnose them
      | appendicitis |
