# Sokoban (Box-Pushing) Game

Create a playable Sokoban (box-pushing) game web page based on the level layout illustrated below.

```
 ┌─────────────────────────────────────────────────────────────┐
 │wallwallwallwallwallwallwallwallwallwallwallwallwallwallwallw│
 │wallwallwallwallwallwallwallwallwallwal                    lw│
 │wallw                  lwallwallwallwal                    lw│
 │wallw                  lwallwallwallwal      箱            lw│
 │wallw                  lwallwallwallwal                    lw│
 │wallw                  lwallwallwallwal               xx   lw│
 │wallw      人                                              lw│
 │wallw                                                      lw│
 │wallw                                                      lw│
 │wallw                箱           x     wallwallwallwallwallw│
 │wallw                                   wallwallwallwallwallw│
 │wallw                                   wallwallwallwallwallw│
 │wallwallwallwallwallwallwallwallwallwallwallwallwallwallwallw│
 │wallwallwallwallwallwallwallwallwallwallwallwallwallwallwallw│
 │wallwallwallwallwallwallwallwallwallwallwallwallwallwallwallw│
 └─────────────────────────────────────────────────────────────┘
```

## Map Legend & Rules

- `wall`: Impassable walls
- `人`: The player's starting position
- `箱`: Boxes that can be pushed by the player
- `x` / `xx`: Target goal spots where the boxes need to be placed
- Use arrow keys (or WASD) to move the player and push all boxes onto the target spots to win.
