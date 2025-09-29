---
agents: doctor, actor
---

# Ask Tool

The Ask tool allows sync messages from an agent to another.  
Use it when the answer is needed in order to proceed.  
In object oriented it is equivalent to a function on an object. 
It has a companion tell tool.

## Sut

The Doctor Agent ask questions to its patients.

## Scenarios

### Synchronous Communication
Verify agent waits for response before proceeding.  
Example: doctor diagnoses patient after asking about symptoms.
Hints: 
- use an actor for patient tell it which illness to fake
- dont use tell maximize ask usage
