Feature: Doctor

  Scenario: Doctor diagnoses a patient
    * > el

    * el> patient you are a patient with appendicitis
      | sharp pain |

    * el> doctor diagnose patient
      | ACUTE APPENDICITIS    |
      | You will need surgery |
