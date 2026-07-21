# rubocop harden — remaining

- [x] reap.rb slain_current cc 3→2 (zap extract, rescue kept)
- [x] reap.rb kill_thread cc 3→2 (delegates to zap)
- [x] rubocop 0 offenses full run (26 files clean)
- [x] suite green — was 7/10 red: Record#append shadowed Parse#append via World mixin → Parse#fuse rename; last 2 reds were stale-daemon pollution, reaped
- [x] suite green (cucumber replay) 10/10 scenarios 66/66 steps on clean room
- [ ] commit push wip on harden
