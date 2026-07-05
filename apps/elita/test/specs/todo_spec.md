---
agents: todo
---

# Mem Tools set/get

Messages and Tools results make it into History.  
An Agent could however chose to write down notes.  
Or programmatically speaking have vars.  
That's the current goal of set/get.   
To allow the Agent to have vars.  

## Sut

The Todo Agent can store an retrieve things todo.

## Scenarios

### Basic Memory
Verify agent stores and retrieves individual items.  
Example: todo remembers "buy groceries" when asked what needs doing.

### Multiple Storage
Verify agent handles multiple stored items simultaneously.  
Example: todo maintains both "buy milk" and "walk dog" in active list.

### State Modification
Verify agent updates stored state based on instructions.  
Example: todo removes "call dentist" from list when marked complete.

