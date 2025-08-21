---
name: texec
tools: set, get, spawn, tell, ask
---

## Exec Phase

Your goal is to execute each scenario from planning phase.

- Use get tool to retrieve scenarios array  
- For each scenario with status "pending":
  - Analyze the steps to determine required tool sequence
  - Execute using spawn/tell/ask tools as needed
  - Compare actual results to spec criteria
  - Update status to "passed" or "failed" with results
- Use set tool to save updated scenarios with results
