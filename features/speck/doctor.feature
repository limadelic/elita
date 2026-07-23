@tape:doctor
Feature: Doctor

  Scenario: speck reads, writes, and runs doctor scenarios
    * > el speck

    * speck> exec doctor

    * speck> log
      | 🧪 doctor_spec                           | Ask Tool                                                                                |
      | 🤖 doctor                                | Medical doctor who diagnoses patients through questioning                               |
      | 🎭 speck as tplan                        |                                                                                         |
      | ✏️ doctor_asks_and_receives_answer       | Doctor asks a patient one question using ask tool and receives an answer before proceed |
      | ✏️ doctor_makes_diagnosis_after_response | After receiving patient's answer, doctor produces a diagnosis based on the answer       |
      | ✏️ synchronous_blocking_behavior         | Doctor's execution blocks waiting for patient response before making diagnosis          |
      | ✏️ single_question_flow                  | Complete diagnostic flow: doctor asks one question, gets answer, produces diagnosis     |
      | 🎭 speck as texec                        |                                                                                         |
      | 🚀 doctor_v1                             | as doctor                                                                               |
      | 🚀 actor_v1                              | as actor                                                                                |
      | 🤔 speck → doctor_v1                     | diagnose actor                                                                          |
      | 🤔 doctor_v1 → actor_v1                  | What symptoms are you experiencing today?                                               |
      | ✨ actor_v1 → doctor_v1                   | Oh where do I even start The pain is the main thing its absolutely unbearable           |
      | ✏️ doctor_asks_and_receives_answer       | Doctor asks a patient one question using ask tool and receives an answer before proceed |
      | ✏️ doctor_makes_diagnosis_after_response | After receiving patient's answer, doctor produces a diagnosis based on the answer       |
      | ✏️ synchronous_blocking_behavior         | Doctor's execution blocks waiting for patient response before making diagnosis          |
      | ✏️ single_question_flow                  | Complete diagnostic flow: doctor asks one question, gets answer, produces diagnosis     |
      | ✨ speck                                  | PASSED                                                                                  |
