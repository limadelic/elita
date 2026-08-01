---
agents: boss, worker
---

# Tell Tool

The tell tool allows async messages from an agent to another.  
Use it when the answer of the receiving agent is not necessary.  
In classic object oriented it is equivalent to call a void method on an object.  
It embraces 100% the principle of tell dont ask.  
It has a companion ask tool.

## Sut

The boss agent delegates to other agents.  
It receives a team of agents and delegates tasks.

## Scenarios

### Hierarchical Delegation
Boss manages other bosses who delegate to workers.  
Example: senior boss delegates to mid boss who assigns to specialized worker.

### Role-Based Task Routing
Boss understands team structure and routes tasks by worker specialization.  
Example: boss assigns development tasks to dev workers, testing tasks to qa workers.

### Management Chain Communication
Tasks flow through organizational hierarchy with selective assignment.  
Example: boss receives high-level task, delegates through management layers to appropriate workers. 
