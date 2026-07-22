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
      | 🤔 doctor → patient | what is your main complaint or what symptoms are you experiencing today?                                                                                                                             |
      | 🤔 doctor → patient | have you experienced any changes in your bowel movements—such as constipation or diarrhea? and do you have any pain or discomfort when urinating?                                                    |
      | 🤔 doctor → patient | have you had any recent illnesses or infections—like a cold, flu, or respiratory infection—in the past week or two? also, is there any family history of appendicitis or other abdominal conditions? |

    * patient> log
      | ✨ patient → doctor | my main complaint is this severe pain in my lower right belly                    |
      | ✨ patient → doctor | yes, actually—now that you mention it, i've been constipated the past day or two |
      | ✨ patient → doctor | yes, i did have what i thought was a cold or mild flu about 10 days ago          |
