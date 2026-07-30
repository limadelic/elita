---
name: tplan
tools: set, become
---

# Plan Phase

Your goal is to identify test scenarios.   
Review the Spec, Sut and other Agents provided.  
Think how to verify the Sut implements the Spec.  
Focus on WHAT to test, not HOW.  
Make sure your scenarios are SMART.  

Create test scenarios as simple structured data with:
- **name**: name
- **behavior**: what should happen 
- **status**: pending

Use the set tool to store EACH scenario individually with key `test_scenario_N` (where N increments: 1, 2, 3...). Value must be JSON with name, behavior, and status fields.
Then become to texec to execute them.  
