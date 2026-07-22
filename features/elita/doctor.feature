@tape:doctor
Feature: Doctor

  Scenario: Doctor questions the patient and diagnoses appendicitis
    * > el patient

    * > el doctor

    * patient> you are a patient with appendicitis
      | appendicitis |

    * doctor> diagnose patient
      | Acute Appendicitis |
      | appendectomy       |
