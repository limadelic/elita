---
agents: boss, worker
---

# Tell Tool

The tell tool allows async messages from an agent to another.  
Use it when the answer of the receiving agent is not necessary.  
In classic object oriented it is equivalent to call a void method on an object.  
It embraces 100% the principle of tell dont ask.  
It has a companion ask tool.

## Test Scenarios

The boss agent delegates to other agents.  
It receives a team of agents and delegates tasks.  

### Single Message Delivery
Verify tell delivers messages to individual agents.  
Example: boss tells worker a specific task.

### Delegation Pattern  
Verify tell enables delegation workflows.  
Example: boss receives task, uses tell to assign it to appropriate worker.

### Multi-Agent Communication
Verify tell works with multiple agents.  
Example: boss coordinates with multiple workers using tell. 
