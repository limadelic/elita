# Gates

- mix test green + mix lint clean ALWAYS
- replay only: $0 cost, under 1 second
- gates met + progress = commit push wip
- NO worktrees, one tree, one change at a time

# Testing

- NO unit tests, NO test-per-module PERIOD
- tests express business behavior in business language
- ONE acceptance flow per feature slice, extend existing flows, never a new file zoo
- $0 tape replay always; one live confirm at the very end only

# Code Styles

- use single words ALWAYS (no compound words)
- ALWAYS import module functions instead of calling Module.func 
- prefer multiple small functions with pattern matching over nested case statements
- use pipeline flow with |> for data transformation
- extract anonymous functions into named functions for clarity