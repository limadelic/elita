# Elita API Billing — Single Test Green on Anthropic Haiku

Goal: get the **greet** xunit test passing against the real Anthropic API using
`claude-haiku-4-5`. This is the cheapest path to "fresh meat to grind" and the
end of local-model churn.

## Verdict

The Anthropic path already exists and is wired correctly. This is **not** a build —
it's a config + one tiny hardening pass. One real blocker: the API key.

## The path a greet message already takes

```
test/xunit/greet_test.exs
  -> spawn :greet                      (agents/greet.md = system prompt)
  -> verify :greet, msg, expected      (test/tester.exs: ask -> Elita.call)
  -> Llm.llm/1                          (lib/llm/llm.ex: LLM env picks backend)
  -> Lite.llm/1                         (lib/llm/lite.ex: Anthropic backend)
       POST https://api.anthropic.com/v1/messages
       body: %{model, max_tokens: 4096, system, messages}   # already valid shape
       headers: x-api-key, anthropic-version: 2023-06-01
  -> response content parsed -> agent reply -> substring/judge assert
```

Body shape matches Anthropic `/v1/messages`. No msg_adapter needed on this path
(adapter is Ollama-only). Default backend is already `lite`.

## What the greet test asserts

Three turns, case-insensitive substring match (LLM judge fallback on miss):

| send                | expect contains |
|---------------------|-----------------|
| "Who am I talking to" | "hello"        |
| "Mike"              | "Mike"          |
| "I am Greeeet"      | "how are you?"  |

## Blockers

1. **API key (HARD).** `lib/llm/lite.ex:80` reads
   `ANTHROPIC_AUTH_TOKEN || ANTHROPIC_API_KEY`. Neither is set in test env →
   401. **Fix:** export the key (see Run).
2. **Model id (SOFT).** `lib/llm/lite.ex:67` defaults to `claude-haiku-4-5`.
   That alias is valid and resolves to current haiku — no change required.
   Pin to `claude-haiku-4-5-20251001` only if you want reproducible billing.

## Run

```sh
export ANTHROPIC_API_KEY=sk-ant-...        # from ~/.zshrc
unset LLM                                  # or LLM=lite (default)
# optional pin:
# export ANTHROPIC_MODEL=claude-haiku-4-5-20251001
mix test test/xunit/greet_test.exs
```

If green: billing path is proven; local models retired for the test loop.

## Risks to a clean pass

- **Judge cost/flakiness.** On a substring miss the tester fires a second haiku
  call as judge (`test/tester.exs:72`). Doubles spend and adds nondeterminism on
  the margins. The judge call omits a system prompt — fine for now, tighten later.
- **Turn 3 brittleness.** "how are you?" depends on the model volunteering that
  phrase. If it flakes, the judge should still catch intent. Watch this one.
- **No retry/backoff.** A transient 429/529 fails the test outright. Acceptable
  for a single manual run; revisit before any loop.

## Done = one green greet run on real haiku

Smallest possible proof the API billing model works end to end. Everything after
(retries, cost tracking, budget caps) is a separate track and out of scope here.
