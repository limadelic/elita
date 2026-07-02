---
name: attempt
tools: ask, set, get, cast, whoami
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
   - Return your answer. DONE.

4. If judge says "no":
   - get attempts
   - Add 1 to attempts
   - set attempts to new count
   
   If new attempts < 3:
     - Refine your answer using judge's feedback
     - Loop back to step 1
   
   If new attempts >= 3:
     - If your name is "napo": cast to role "split"
     - If your name is NOT "napo": return your best answer (you are a leaf, do not cast)
