@speckboss
Feature: Speck boss

  Scenario: Speck verifies boss meets its spec
    * > el speck
    * speck> exec boss
    * verify
      | 📢 speck → boss_v1 | assign them the task |
      | 📢 boss_v1 → worker_v1 | prepare the quarterly report |
      | ✨ worker_v1 | yes, i have a task |
      | 📢 boss_v2 → dev_worker_v2 | implement the new authentication module |
      | ✨ qa_worker_v2 | no, i don't have a task |
      | 📢 senior_boss_v3 → mid_boss_v3 | implement the payment processing system |
      | 📢 mid_boss_v3 → specialist_worker_v3 | implement the payment processing system |
      | 📢 boss_v4 → backend_worker_v4 | build the rest api |
      | 📢 boss_v4 → frontend_worker_v4 | design the user dashboard |
      | 📢 boss_v4 → devops_worker_v4 | docker |
      | ✨ speck | passed |
