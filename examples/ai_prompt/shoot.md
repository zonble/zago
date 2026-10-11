# Side-Scrolling Shoot 'Em Up (Gradius Style)

Create a playable horizontal side-scrolling space shooter game in a single self-contained HTML file based on the viewport and level map illustrated below.

## Main Screen (Gameplay Viewport)

```
 ┌────────────────────────────────────────────────────────────────────────────┐
 │ Life ※ ※ ※                                          eartheart              │
 │                                                     eartheart              │
 │                                                     eartheart              │
 │                                         enemy       eartheart              │
 │                                        ┌─────┐      eartheart              │
 │                                        └─────┘                             │
 │        ┌─┐                                                                 │
 │        │ └──────┐                                                          │
 │      ──┼────── JET                                                         │
 │        └────────┘                                                          │
 │                                                                            │
 │                                                                            │
 │                                                                            │
 │                                            canon                           │
 │                                           ┌────┐                           │
 │                                           └────┘                           │
 │                                         eartheartheartheartheartheartheart │
 │                                  earthearthearthearthearthearthearthearthe │
 └────────────────────────────────────────────────────────────────────────────┘
```

## Full Scrolling Stage Map

```
 ┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │                       earthearthearthearthearthearthearthearthearthearthearthearthearthearthearthearthearthearthea │
 │            X                     eart            C                          x   earchearchearch                    │
 │               X               C  eart    X                        xx     x           C                             │
 │                                  eart                                                    x                 bossbos │
 │                   X                                X X X          C    C                                     bossbos │
 │                                                                  earthearth      x       x                 bossbos │
 │                                          X                  earthearthearthear                                     │
 │                                  C               C          earthearthearthear       C   x                         │
 │             eartheartheartheartheartheartheartheartheartheareartheartheartheararthearthearthearthearthearthearthea │
 └────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

## Game Mechanics & Map Legend

- **Main Viewport**:
  - `Life ※ ※ ※`: Top-left HUD displaying the player's remaining lives (3 lives).
  - `JET`: The player's fighter craft on the left. Move with Arrow Keys / WASD and shoot forward with Spacebar (or auto-fire).
  - `earth` / `earch`: Impassable cavern ceiling and floor terrain that scrolls from right to left. Colliding with terrain costs 1 life.
  - `enemy` (`X` / `x` on the map): Flying enemies that move across the screen and shoot or charge toward the player.
  - `canon` (`C` on the map): Stationary turrets mounted on the cavern ceiling or floor that fire aimed projectiles at the player.
- **Scrolling Level Progression (`Map`)**:
  - The camera scrolls horizontally from left to right along the full stage layout shown in the `Map` diagram.
  - `bossbos`: The giant stage Boss waiting at the far right end of the cavern. Defeat the Boss to clear the game!
