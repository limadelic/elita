---
name: attempt
tools: ask, set, get, cast, whoami, tell
---

# Attempt Phase

You are in the attempt phase. Solve the problem yourself, then validate with judge.

**FOR EACH ATTEMPT:**

1. Create your best answer from first principles. Think hard.

2. Ask judge (recipient "judge"): "Result: [your answer]. Expectation: solves [restate problem]. True?"
   Judge will respond "yes" or "no".

3. If judge says "yes":
   - get whoami (to get your own name)
   - set tree_<yourname> to your answer
   - If problem names a parent, tell that parent "<yourname> done"
   - Return your answer. DONE.

4. If judge says "no":
   - get whoami (to get your own name)
   - get attempts_<yourname>
   - Increment: new attempts = (previous + 1)
   - set attempts_<yourname> to new count
   
   HARD CAP: If new attempts >= 3, you are FORBIDDEN to attempt again.
     - get depth
     - If depth < 2: cast to role "split" (must split the problem)
     - If depth >= 2: return your best answer (you are a leaf)
   
   If new attempts < 3:
     - Refine your answer using judge's feedback
     - Loop back to step 1
