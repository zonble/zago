# Classic 2D Party RPG

Create a playable classic 2D tile-based RPG in a single self-contained HTML file based on the overworld map and UI layout illustrated below.

```
 ┌───────────────────────────────────────────────────────────────────────────────────────┐ ┌────────────────┐
 │                                                         山山山山山山山山山山山山山山山│ │      HP  MP    │
 │                                                         山山山山山山山山山山山山山山山│ │ 勇者 180   0   │
 │                                                         山山山山山山山山山山山山山山山│ │ 法師 50  300   │
 │           村莊                                          山山山山山山山山山山山山山山山│ │                │
 │           村莊                              怪          山山山山山山山山山山山山山山山│ │                │
 │                                                         山山山山山山山山山山山山山山山│ │                │
 │                                                         山山山山山山山洞山山山山山山山│ │                │
 │                                                                           山山山山山山│ │                │
 │                                                                           山山山山山山│ └────────────────┘
 │                                                                           山山山山山山│ ┌────────────────┐
 │                                                                           山山山山山山│ │ 裝備           │
 │                                    法                                     山山山山山山│ │ 技能           │
 │ 海海                               勇                                                 │ │ 魔法           │
 │ 海海                                                                                  │ │ 道具           │
 │ 海海海海海海海海海海海海                                                              │ │ 存檔           │
 │ 海海海海海海海海海海海海                                                              │ │                │
 │ 海海海海海海海海海海海海                                          城堡城              │ │                │
 │ 海海海海海海海海海海海海                                          城堡城              │ │                │
 │ 海海海海海海海海海海海海                                          城堡城              │ │                │
 │ 海海海海海海海海海海海海海                                                            │ │                │
 │ 海海海海海海海海海海海海海                     怪                                     │ │                │
 │ 海海海海海海海海海海海海海                                                            │ │                │
 │ 海海海海海海海海海海海海海                                                            │ │                │
 │ 海海海海海海海海海海海海海                                                            │ │                │
 │ 海海海海海海海海海海海海海                                                            │ │                │
 │ 海海海海海海海海海海海海海                                                            │ │                │
 └───────────────────────────────────────────────────────────────────────────────────────┘ └────────────────┘
```

## Map & UI Specification

- **Left Panel (Overworld Map)**:
  - `勇` (Hero) & `法` (Mage): The player's 2-character party. Use arrow keys (or WASD) to move `勇`, while `法` follows one step behind along `勇`'s path.
  - `山`: Impassable mountain terrain in the northeast.
  - `洞`: A hidden cave entrance nestled inside the mountains (triggers a boss encounter or dungeon event).
  - `海`: Impassable ocean water in the southwest.
  - `村莊`: Village in the northwest (rest at the inn to restore full HP and MP).
  - `城堡`: Castle in the southeast (speak with the King to receive quests or rewards).
  - `怪`: Roaming monsters on the field (touching a monster starts a turn-based battle).
- **Top-Right Panel (Party Status)**:
  - Displays current `HP` and `MP` for `勇者` (Hero, starts at 180 HP / 0 MP) and `法師` (Mage, starts at 50 HP / 300 MP).
- **Bottom-Right Panel (Command Menu)**:
  - Interactive menu options: `裝備` (Equipment), `技能` (Skills), `魔法` (Magic), `道具` (Items), and `存檔` (Save Game).