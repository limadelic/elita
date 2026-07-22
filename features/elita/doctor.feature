@tape:doctor
Feature: Doctor

  Scenario: Doctor diagnoses a patient
    * > el patient

    * > el doctor

    * patient> you are a patient with appendicitis
      | sharp pain |

    * doctor> diagnose patient
      | ACUTE APPENDICITIS    |
      | You will need surgery |
