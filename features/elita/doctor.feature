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

    * doctor> log
      | 🤔 doctor → patient | what is your main complaint today? what symptoms are you experiencing? |
      | 🤔 doctor → patient | have you experienced any diarrhea or constipation recently, or any changes in your bowel habits before the pain started? |
      | 🤔 doctor → patient | when you press on your lower right abdomen, does the pain increase? and if you press and then quickly release your hand, does it cause a sharp pain (rebound tenderness)? |
