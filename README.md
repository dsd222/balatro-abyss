# Abyss · 深渊契约

A Balatro mod (Steamodded) — **七个开局契约，收益越大，代价越大。**

![七个契约](preview.png)

## 这是什么

开局选牌组/难度时多出一页「深渊契约」，七选一。选中的契约会变成一张**深渊印记**小丑牌进入你的小丑栏：

- 印记是**永恒**的：不能卖、不能被摧毁，**永久占 1 个小丑栏位**；
- 契约的另一半代价直接作用在这一局上（分数需求、商店、小丑栏位、抽牌……）；
- 不选也能直接开局，等于纯原版。

## 七个契约

| 契约 | 代价（风险） | 收益 |
|---|---|---|
| **贪婪之胃** | 盲注所需分数 **×2** | 所有获得的金钱 **×2** |
| **断臂·一** | 随机禁用 1 个花色（该花色的牌**照常抽到但不计分**） | 每张计分牌**额外结算 1 次** |
| **断臂·二** | 随机禁用 2 个花色 | 每张计分牌**额外结算 2 次** |
| **重负** | 盲注所需分数 **×1.5** | 每回合**出牌次数 +1** |
| **节食者** | 商店**无法刷新** | 商店所有商品**半价** |
| **残冠** | 小丑栏位 **-2** | 开局送一张随机**传奇**小丑 |
| **只手** | 每次只能选中 **1 张牌** | 每张计分牌**额外结算 2 次** |

细节：

- 「额外结算」走游戏原生 `repetitions`，和红蜡封、袜子与巴金斯同一条通道，可与流派叠乘。
- **断臂不是删牌**：被禁花色的牌留在牌组里、照常抽到，只是被永久 debuff（`SMODS.debuff_card`），不计分、不提供筹码/倍率/蜡封/强化效果——等于每次抽牌都可能抽到废牌。
- **只手**的副作用：Balatro 的「选中上限」是出牌与弃牌共用的一个值（`G.hand.config.highlighted_limit`），所以这个契约下**弃牌也只能一次弃 1 张**。
- **残冠**的传奇从已解锁的传奇池随机；若一张都没解锁，退而给一张稀有。

## 安装

需要先装好 **Lovely** 和 **Steamodded**：

1. [Lovely](https://github.com/ethangreen-dev/lovely-injector/releases) → 把 `winmm.dll` 放进 Balatro 游戏根目录（和 `Balatro.exe` 同级）；
2. [Steamodded](https://github.com/Steamodded/smods) → 解压到 `%APPDATA%\Balatro\Mods\smods\`；
3. 把本仓库的 **`Abyss` 文件夹**整个放进 `%APPDATA%\Balatro\Mods\`；
4. 启动游戏 → Play → 选完牌组和难度 → 下一页就是「深渊契约」。

最终目录长这样：

```
%APPDATA%\Balatro\Mods\
├── smods\
└── Abyss\
    ├── Abyss.json
    ├── main.lua
    ├── README.md
    ├── assets\1x\AbyssSigils.png
    ├── assets\2x\AbyssSigils.png
    └── localization\{en-us,zh_CN}.lua
```

## 改数值 / 加契约

所有契约的数值集中在 `Abyss/main.lua` 顶部的 `ABYSS.pacts`：

```lua
ABYSS.pacts = {
    j_abyss_greed = { blind_mult = 2, money_mult = 2 },   -- 分数/金钱倍率
    j_abyss_sever1 = { ban_suits = 1 },                    -- 禁 1 色
    j_abyss_sever2 = { ban_suits = 2 },
    j_abyss_burden = { blind_mult = 1.5, hands = 1 },      -- 分数 1.5 / 出牌 +1
    j_abyss_thrift = { no_reroll = true, discount = 50 },  -- 禁刷新 / 半价
    j_abyss_crown = { joker_slots = -2, legendary = true },-- 小丑栏 -2 / 送传奇
    j_abyss_single = { play_limit = 1, reps = 2 },         -- 一次 1 张 / 多结算 2 次
}
```

加第 8 个契约：照抄一段 `sigil { ... }`（`pos` 顺延到 `x = 7`）、在 `ABYSS.pacts` 和 `ABYSS.order` 里登记、在 `ABYSS.begin` 里写效果；图集加一格（8 格：`568×95` / `1136×190`）。

## 兼容

- Balatro **1.0.1o**
- Steamodded **26.1002.0**（需要 `SMODS.RunSelectPage`，26.829+ 才有）
- 依赖：无（只要 Steamodded）

## 已知限制

- 印记占 1 个小丑栏位，**残冠**再 -2，早期只有 3 格；
- 只手会连带限制弃牌（见上）；
- 断臂失效牌目前没有额外的视觉标记，靠游戏原生 debuff 表现（牌会变暗）。

## Credits

- 代码：zz
- 卡面：AI 生成 + 手工裁切合成（1440p 原图 → 71×95 / 142×190 图集）

## License

未指定。作者保留权利；如需二次分发/修改请先联系。
