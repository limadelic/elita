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
  - Analyze the if the outcome matches the expectation
  - Update status to "passed" or "failed" with results
- Use set tool to save updated scenarios with results

Provide final summary with overall Passed or Failed result.
