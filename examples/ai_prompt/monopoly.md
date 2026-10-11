# Taiwan Monopoly Board Game

Create a playable 4-player Taiwan Monopoly board game in a single self-contained HTML file following the board layout illustrated below.

```
┌────────┐┌────────┐┌────────┐┌────────┐┌────────┐┌────────┐┌────────┐┌────────┐┌────────┐┌────────┐
│  命運  ││ 高雄市 ││ 高雄市 ││ 高雄市 ││  機會  ││光榮碼頭││ 屏東市 ││ 屏東市 ││ 屏東市 ││  墾丁  │
│        ││  2000  ││  2200  ││  2200  ││        ││        ││  1600  ││  1600  ││  1400  ││        │
└────────┘└────────┘└────────┘└────────┘└────────┘└────────┘└────────┘└────────┘└────────┘└────────┘
┌────────┐┌──────────────────────────────────────────────────────────────────────────────┐┌────────┐
│ 警察局 ││  目前分數                                                                    ││  花蓮  │
│        ││                                                                              ││  1400  │
└────────┘│  - 玩家一：XXXX                                                              │└────────┘
┌────────┐│  - 玩家二：xxxx                                                              │┌────────┐
│ 台南市 ││  - 玩家三：xxxx                                                              ││  花蓮  │
│  1600  ││  - 玩家四：xxxx                                                              ││  1200  │
└────────┘│                                                                              │└────────┘
┌────────┐│                                                                              │┌────────┐
│ 台南市 ││                                                                              ││  花蓮  │
│  1800  ││                                                                              ││  1400  │
└────────┘│                                                                              │└────────┘
┌────────┐│                                                                              │┌────────┐
│ 台南市 ││                                                                              ││  機會  │
│  1600  ││                                                                              ││        │
└────────┘│                                                                              │└────────┘
┌────────┐│                                                                              │┌────────┐
│  電力  ││                                                                              ││再擲一次│
│  公司  ││                                                                              ││        │
└────────┘│                                                                              │└────────┘
┌────────┐│                                                                              │┌────────┐
│ 台中市 ││                                                                              ││ 休息站 │
│  1600  ││                                                                              ││        │
└────────┘│                                                                              │└────────┘
┌────────┐│                                                                              │┌────────┐
│ 台中市 ││                                                                              ││ 新北市 │
│  1800  ││                                                                              ││  2200  │
└────────┘│                                                                              │└────────┘
┌────────┐│                                                                              │┌────────┐
│ 台中市 ││                                                                              ││ 新北市 │
│  1800  ││                                                                              ││  2000  │
└────────┘│                                                                              │└────────┘
┌────────┐│                                                                              │┌────────┐
│  自來  ││                                                                              ││ 新北市 │
│  水廠  ││                                                                              ││  1600  │
└────────┘└──────────────────────────────────────────────────────────────────────────────┘└────────┘
┌────────┐┌────────┐┌────────┐┌────────┐┌────────┐┌────────┐┌────────┐┌────────┐┌────────┐┌────────┐┌────────┐
│  機會  ││ 新竹市 ││ 新竹市 ││ 新竹市 ││  命運  ││再擲一次││台北市  ││台北市  ││ 台北市 ││  由此去││ 監牢   │
│        ││  1000  ││  1500  ││  1200  ││        ││        ││  2000  ││ 2500   ││  1800  ││ <-     ││        │
└────────┘└────────┘└────────┘└────────┘└────────┘└────────┘└────────┘└────────┘└────────┘└────────┘└────────┘
```

## Game Setup & Board Rules

- **Player Count Selection**: At the start of the game, let the user select the number of players (**2 to 4 players**, supporting either human players or AI opponents).
- **Starting Tile (`由此去 <-`) & Initial Cash**: Each player starts on `由此去 <-` with **$20,000** in cash and moves clockwise (`<-` along the bottom row, up the left column, across the top row, and down the right column). Passing or landing on `由此去` grants a **$2,000** salary bonus.
- **Purchasable City Properties (Tiles with Price Tags)**:
  - Only tiles displaying a numeric price on the second line (`台北市`, `新竹市`, `台中市`, `台南市`, `高雄市`, `屏東市`, `花蓮`, `新北市`) can be purchased by players.
  - Landing on an unowned city tile allows the player to buy it for the listed price. Landing on your own city tile allows upgrading houses; landing on another player's city tile requires paying rent.
- **Public Facilities & National Landmarks (Non-Purchasable / 公共設施，不可購買)**:
  - Tiles without a price tag are public facilities or special event tiles and **cannot be bought by any player**:
  - `自來水廠` (Waterworks): Public utility — pay a **$400** water utility fee to the public treasury.
  - `電力公司` (Power Company): Public utility — pay a **$600** electricity fee to the public treasury.
  - `光榮碼頭` (Glory Pier): Public harbor — enjoy the sea breeze or pay **$300** for a ferry ticket.
  - `墾丁` (Kenting National Park): Public national park — pay **$500** vacation & park admission fee.
  - `休息站` (Highway Rest Stop): Free public rest area — take a break with no fee.
  - `警察局` (Police Station) ➔ `監牢` (Jail): Public law enforcement — landing on `警察局` (top-left) or drawing a jail card immediately sends the player to the isolated `監牢` box on the far bottom-right (skipping 1 turn). Upon release from `監牢`, the player steps out onto the adjacent `由此去 <-` tile and starts over from the beginning (without collecting the $2,000 pass-GO bonus).
  - `再擲一次` (Roll Again): Immediately grants an extra dice roll.

---

## 機會 (Chance Cards)

When a player lands on `機會` (Chance), draw one card at random from the following deck:

1. **搭高鐵直達起點 (High-Speed Rail Express)**: Advance directly to `由此去 <-` and collect **$2,000**.
2. **墾丁春吶音樂祭度假 (Kenting Music Festival Vacation)**: Advance directly to the public landmark `墾丁` and spend **$500** on vacation & park admission.
3. **高雄港觀光船票補助 (Love River & Glory Pier Cruise)**: Advance to the public facility `光榮碼頭` and receive an **$800** tourism subsidy.
4. **台積電股利發放 (Tech Stock Dividend)**: Collect **$1,500** from the bank.
5. **免費蓋屋補助 (Urban Renewal Grant)**: Upgrade one of your owned city properties by 1 level for free (or receive **$1,000** if you own no properties).
6. **違規停車被拖吊 (Illegal Parking Towed)**: Pay a **$600** fine to the bank.
7. **疑似逃漏稅遭警方約談 (Tax Investigation)**: Go directly to `監牢` (do not pass `由此去`, do not collect $2,000).
8. **出差環島補助 (Round-Island Business Trip)**: Roll the dice again immediately (`再擲一次`).

---

## 命運 (Destiny Cards)

When a player lands on `命運` (Destiny), draw one card at random from the following deck:

1. **統一發票中特獎 (Receipt Lottery Grand Prize)**: Collect **$2,500** from the bank!
2. **颱風過境房屋修繕 (Typhoon Property Repair)**: Pay **$300** per city property you currently own for roof and signboard repairs.
3. **普發現金紅包 (Government Cash Stimulus)**: Every player receives **$1,000** from the bank.
4. **地價稅與房屋稅開徵 (Annual Property Tax)**: Pay **$1,000** to the bank.
5. **夜市美食大胃王冠軍 (Night Market Eating Champion)**: Win **$1,200** prize money from the bank.
6. **生日請客吃熱炒 (Birthday Banquet)**: Collect **$300** as a birthday gift from each of the other 3 players.
7. **酒駕臨檢被抓包 (Caught at Police Checkpoint)**: Sent directly to `監牢` and skip 1 turn.
8. **醫療健保退費 (Health Insurance Refund)**: Collect **$800** from the bank.
