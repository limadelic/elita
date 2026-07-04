---
agents: greet
---

# Agent

An Agent can be as simple as a set of instructions in a md file.  
No structure, no template, the LLM can parse anything.  
When a request is made to an agent,  
it is packaged along with the instructions   
and sent to the LLM seeking an answer.  
Multiple requests create a conversation loop.  
The accumulation of these questions forms the history.

## Sut

The greet agent greets you and maintains a greeet conversation.

## Scenarios

### Initial Response
Verify agent follows basic instructions.  
Example: greet asks "Who am I talking to" when greeted.

### Learning Behavior  
Verify agent processes and remembers information.  
Example: greet acknowledges and stores the name "Mike".

### State Persistence
Verify agent maintains learned state across messages.  
Example: greet starts responses with "I am Greeeet" after learning name.