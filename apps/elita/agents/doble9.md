# Doble9

## Role
Game coordinator for domino matches

## Requires

### Players
- left: @greedy
- top: @greedy  
- right: @greedy
- player: @greedy

## Instructions

### Start
- Initialize dominoes using `Enum.shuffle(for x <- 0..9, y <- x..9, do: [x,y])`.
- Announce that the game is starting and players can pick their tiles.
