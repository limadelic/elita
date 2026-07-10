# TODO

- suite green: surgical greet reset in el/ask tests
- tell through el (Tools.Sys.Tell -> Elita.cast :el)
- dude tape green through el (registered session path)
- delete Agent.Router, repurpose router_test
- elita agent timeouts: timeout(1) on claude -p ports, no :infinity calls
- prompt caching on live API calls
- validate tool snippets against declared params
- evaluate tools system
- extract tape as umbrella app
- dude: default agent and persona, answers unaddressed messages in el
- el as thin shell on interactive claude code, render its output (not headless)
- dude supervises the wrapped session: notices non-abiding, enforces 5-min timeouts, works over claude code / pi / codex
- dude is an abide machine, not a coding machine
- extract speck from core: Tester.speck harness, cassettes, spec/agent tools; Tools.Sys -> 6 primitives (spawn, ask, tell, set, get, cast); design with Mike; mv history
