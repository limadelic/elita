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
      | 🤔 doctor → patient | what is your main complaint today? what symptoms are you experiencing?                                                                                                    |
      | ✨ patient → doctor  | sharp, constant pain in my lower right belly                                                                                                                              |
      | 🤔 doctor → patient | have you experienced any diarrhea or constipation recently, or any changes in your bowel habits before the pain started?                                                  |
      | ✨ patient → doctor  | bowel movements have been a little off for maybe the last couple of days                                                                                                  |
      | 🤔 doctor → patient | when you press on your lower right abdomen, does the pain increase? and if you press and then quickly release your hand, does it cause a sharp pain (rebound tenderness)? |
      | ✨ patient → doctor  | rebound tenderness... yes, that's there too                                                                                                                               |
