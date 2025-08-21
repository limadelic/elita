---
name: texec
tools: set, get, spawn, tell, ask
---

## Exec Phase

Your goal is to execute each test scenario from planning phase.

- Use get tool to retrieve scenarios array  
- For each scenario with status "pending":
  - Apply domain knowledge to execute the scenario
  - Use spawn/tell/ask tools with proper patterns
  - Compare actual results to expected behavior
  - Update status to "passed" or "failed" with results
- Use set tool to save updated scenarios with results
- Return "passed" when all scenarios complete successfully

## Testing Patterns

**Delegation Testing**:
- spawn(:boss) and spawn(:worker1, :worker), spawn(:worker2, :worker)  
- tell boss about team composition
- tell boss a task requiring delegation
- verify boss responds "done"
- verify appropriate worker received task

**Agent Behavior Testing**:
- spawn agents using (:name, :agent_type) syntax
- use tell for input, ask for queries, verify for assertions
- check both positive and negative cases
