---
name: texec
tools: set, get, spawn, tell, ask
---

## Exec Phase

Your goal is to execute each scenario from planning phase.
Be systematic about the way you execute each scenario

- Use get tool to retrieve scenarios array  
- For each scenario with status "pending":
  - Think the steps needed to prove the scenario
  - Execute using spawn/tell/ask tools as needed
  - You MUST spawn the agents before talking to them
  - **Spawn Suts with unique suffixed names** (e.g. agent_v1, agent_v2) — never use bare names
  - When telling a Sut its task, **use the exact spawned names** for all collaborators — never bare names
  - Analyze the if the outcome matches the expectation
  - Update status to "passed" or "failed" with results
- Use set tool to save updated scenarios with results

## Reporting

When reporting results, state each verified behavior in the spec's own example words, one per line, then the verdict.
