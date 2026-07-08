@tape:speckboss
Feature: Boss

  Scenario: Boss delegates tasks to workers
    * > el speck
    * speck> exec boss
      | 📢 speck → boss_v1                    | assign them the task    |
      | 📢 boss_v1 → worker_v1                | quarterly report        |
      | ✨ worker_v1                           | yes, i have a task      |
      | 📢 boss_v2 → dev_worker_v2            | authentication          |
      | ✨ qa_worker_v2                        | no, i don't have a task |
      | 📢 senior_boss_v3 → mid_boss_v3       | payment processing      |
      | 📢 mid_boss_v3 → specialist_worker_v3 | payment processing      |
      | 📢 boss_v4 → backend_worker_v4        | REST API                |
      | 📢 boss_v4 → frontend_worker_v4       | dashboard               |
      | 📢 boss_v4 → devops_worker_v4         | docker                  |
      | 📢 boss_v5 → worker_v5                | code review             |
      | ✨ worker_v5                           | pull request            |
      | 📢 boss_v6 → worker_v6                | ready                   |
      | ✨ worker_v6                           | this task is vague      |
      | ✨ speck                               | PASSED                  |
