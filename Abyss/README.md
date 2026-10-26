# Abyss · 深渊契约

Balatro（Steamodded）mod：**开局选一个契约，收益越大，代价越大。**

## 安装

已经装好了：

```
%APPDATA%\Balatro\Mods\Abyss\
├── Abyss.json
├── main.lua
├── localization\        en-us.lua / zh_CN.lua
└── assets\1x,2x\        AbyssSigils.png（7 格，71x95 / 142x190）
```

前置：游戏目录 `winmm.dll`（Lovely）+ `Mods\smods\`（Steamodded）——也都装好了。

## 怎么玩

**Play → 选完牌组、难度后，会多出一页「深渊契约」**（2x4 七张卡）。选一张 → Play，进入游戏时：

- 选中的契约变成一张**深渊印记**小丑牌，直接进你的小丑栏；
- 印记是**永恒**的：不能卖、不能被摧毁，**永久占 1 个小丑栏位**（代价的一部分）；
- 不选也能直接开局，等于无契约（纯原版）。

## 七个契约

| 卡面 | 名字 | 代价（风险） | 收益 |
|---|---|---|---|
| 金币 | 贪婪之胃 | 盲注所需分数 **×2** | 所有**获得的金钱 ×2** |
| 断手 | 断臂·一 | 随机**禁用 1 个花色**（该花色牌**照常抽到，但不计分**） | 每张计分牌**额外结算 1 次** |
| 双手 | 断臂·二 | 随机**禁用 2 个花色**（同上，共 26 张废牌） | 每张计分牌**额外结算 2 次** |
| 石板 | 重负 | 盲注所需分数 **×1.5** | 每回合**出牌次数 +1** |
| 断币 | 节食者 | **无法刷新商店** | 商店价格**减半** |
| 破冠 | 残冠 | **小丑栏位 -2** | 开局送一张随机**传奇**小丑 |
| 三重牌 | 只手 | **每次只能选中 1 张牌** | 每张计分牌**额外结算 2 次（共 3 次）** |

几点说明：

- 「额外结算」走游戏原生 `repetitions`，和红蜡封、袜子与巴金斯同一条通道，可与流派叠乘。
- **断臂不是删牌**：被禁花色的牌留在牌组里、照常抽到，只是被永久 debuff（`SMODS.debuff_card`）——不能计分、不提供筹码/倍率/蜡封/强化效果。等于每次抽牌都可能抽到废牌，手牌质量变差；流派上反而是**更难**凑同花顺子，不是更容易。
- **只手有个隐藏副作用**：Balatro 的「选中上限」是出牌和弃牌共用的一个值（`G.hand.config.highlighted_limit`），所以这个契约下**弃牌也只能一次弃 1 张**。如果只想要「出牌 1 张、弃牌正常」，得改 `G.FUNCS.play_cards` 那条路，代价是选中 5 张按出牌会没反应，体验更差。
- 残冠送的传奇从 `G.P_JOKER_RARITY_POOLS[4]` 里随机挑；如果这个档位一张都没解锁，会退而给一张稀有。

## 实现要点（想改的时候看这里）

| 机制 | 做法 |
|---|---|
| 分数需求 | 包装全局 `get_blind_amount()`，乘 `ABYSS.blind_mult` |
| 金钱 | 包装 `ease_dollars()`，只对**正数**乘 `ABYSS.money_mult`（花费不变） |
| 禁花色 | 开局 `SMODS.destroy_cards()` 从 `G.playing_cards` 删牌 |
| 额外结算 | 印记的 `calculate` 在 `context.repetition` 时返回 `repetitions` |
| 出牌次数 | `G.GAME.starting_params.hands` + `round_resets.hands` |
| 商店半价 | `G.GAME.discount_percent += 50`，再 `v:set_cost()` 刷新价格 |
| 禁止刷新 | 包装 `G.FUNCS.can_reroll`（变灰）和 `G.FUNCS.reroll_shop`（空操作） |
| 小丑栏 -2 | `G.jokers.config.card_limit -= 2` |
| 传奇赠送 | `G.P_JOKER_RARITY_POOLS[4]` 随机取一个 → `SMODS.add_card` |
| 一次一张 | `G.hand.config.highlighted_limit = 1`（出牌/弃牌共用） |
| 不进商店 | 生成印记之后把 7 个 key 写进 `G.GAME.banned_keys`（先生成再禁） |

改数值：`main.lua` 顶部的 `ABYSS.pacts` 表。

## 加第 8 个契约

1. 照抄一个 `sigil { key = 'xxx', pos = { x = 7, y = 0 }, ... }`；
2. `ABYSS.pacts` 加一行、`ABYSS.order` 里加 key；
3. `ABYSS.begin` 里加效果（改全局倍率后记得调 `rescale_current_blind()`）；
4. 图集加一格（8 格宽：568x95 / 1136x190），`grid_size` 改成 `{2,4}` 已够 8 个。

## 卸载

删 `%APPDATA%\Balatro\Mods\Abyss` 即可。要完全回原版：再删 `Mods\smods` 和游戏目录的 `winmm.dll`。

## 已验证（2026-10-25 实机跑过）

- 7 个契约牌注册成功，中文名/描述/图集（497px 宽 = 7 格）正常
- 贪婪之胃：盲注 300 → 600；`+$10` 实际进账 `+$20`
- 断臂·一：牌组 52 → 39、花色归零；`eval_card` 返回 `repetitions = 1`
- 重负：`round_resets.hands` 4 → 5
- 节食者：`discount_percent` = 50、刷新按钮变灰且点击无效
- 残冠：小丑上限 5 → 3，并成功送出传奇 `j_triboulet`
- 只手：`highlighted_limit` = 1，`eval_card` 返回 `repetitions = 2`（共结算 3 次）
