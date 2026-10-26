--- Abyss ---------------------------------------------------------------
--- Risk/reward "pacts" chosen on the run-select screen, before a run.
--- Each pact is a Sigil: an eternal joker that occupies one joker slot and
--- carries the pact's upside, while the downside is applied to the run.
---------------------------------------------------------------------------

ABYSS = ABYSS or {}

local SUITS = { 'Hearts', 'Diamonds', 'Spades', 'Clubs' }

ABYSS.pacts = {
    j_abyss_greed = { blind_mult = 2, money_mult = 2 },
    j_abyss_sever1 = { ban_suits = 1 },
    j_abyss_sever2 = { ban_suits = 2 },
    j_abyss_burden = { blind_mult = 1.5, hands = 1 },
    j_abyss_thrift = { no_reroll = true, discount = 50 },
    j_abyss_crown = { joker_slots = -2, legendary = true },
    j_abyss_single = { play_limit = 1, reps = 2 },
}

ABYSS.order = {
    'j_abyss_greed', 'j_abyss_sever1', 'j_abyss_sever2', 'j_abyss_burden',
    'j_abyss_thrift', 'j_abyss_crown', 'j_abyss_single',
}

ABYSS.active = nil
ABYSS.blind_mult = 1
ABYSS.money_mult = 1
ABYSS.banned_suits = {}
ABYSS.sever_suits = {}

--- Sever pacts do NOT remove the banned suits: the cards stay in the deck and
--- keep getting drawn, they are simply debuffed so they never score.
function ABYSS.is_sever_suit(card)
    if not card or not card.base or not card.base.suit then return false end
    for _, s in ipairs(ABYSS.sever_suits or {}) do
        if card.base.suit == s then return true end
    end
    return false
end

function ABYSS.debuff_severed(card)
    if not ABYSS.is_sever_suit(card) then return false end
    if not (G.GAME and G.GAME.blind) then return false end
    pcall(function() SMODS.debuff_card(card, true, 'abyss_sever') end)
    return true
end

---------------------------------------------------------------------------
-- Atlas
---------------------------------------------------------------------------
SMODS.Atlas {
    key = 'abyss_sigils',
    path = 'AbyssSigils.png',
    px = 71,
    py = 95,
}

---------------------------------------------------------------------------
-- Global hooks (installed once)
---------------------------------------------------------------------------
if not ABYSS.hooked then
    ABYSS.hooked = true

    -- Blind requirements. Every blind is sized through this function, so
    -- scaling here covers the current blind and every later one.
    local _blind_amount = get_blind_amount
    function get_blind_amount(ante)
        local v = _blind_amount(ante)
        if ABYSS.blind_mult and ABYSS.blind_mult ~= 1 then
            return math.floor(v * ABYSS.blind_mult)
        end
        return v
    end

    -- Money gained (positive amounts only; costs keep their real price).
    local _ease_dollars = ease_dollars
    function ease_dollars(mod, instant)
        if ABYSS.money_mult and ABYSS.money_mult ~= 1 and type(mod) == 'number' and mod > 0 then
            mod = mod * ABYSS.money_mult
        end
        return _ease_dollars(mod, instant)
    end

    -- No rerolls: grey the button out and make it a no-op.
    local _can_reroll = G.FUNCS.can_reroll
    G.FUNCS.can_reroll = function(e)
        _can_reroll(e)
        if ABYSS.no_reroll then
            e.config.colour = G.C.UI.BACKGROUND_INACTIVE
            e.config.button = nil
        end
    end
    local _reroll_shop = G.FUNCS.reroll_shop
    G.FUNCS.reroll_shop = function(e)
        if ABYSS.no_reroll then return end
        return _reroll_shop(e)
    end

    -- Cards that enter the run later (packs, tarots, card destruction) get the
    -- same treatment as the starting deck.
    local _create_card = create_card
    function create_card(...)
        local c = _create_card(...)
        if c then ABYSS.debuff_severed(c) end
        return c
    end
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function pick_suits(n)
    local pool = {}
    for _, s in ipairs(SUITS) do pool[#pool + 1] = s end
    local out = {}
    for i = 1, n do
        if #pool == 0 then break end
        local idx = pseudorandom(pseudoseed('abyss_suit_' .. i), 1, #pool)
        out[#out + 1] = table.remove(pool, idx)
    end
    return out
end

local function suit_list_text(suits)
    if not suits or #suits == 0 then return localize('k_abyss_random') end
    local names = {}
    for _, s in ipairs(suits) do names[#names + 1] = localize(s, 'suits_plural') end
    return table.concat(names, ' / ')
end

-- Recompute the chips of the blind that has already been set this round.
local function rescale_current_blind()
    local b = G.GAME and G.GAME.blind
    if not b or not b.chips or b.chips <= 0 then return end
    b.chips = get_blind_amount(G.GAME.round_resets.ante) * (b.mult or 1)
        * (G.GAME.starting_params.ante_scaling or 1)
    b.chip_text = number_format(b.chips)
    if G.HUD_blind and G.HUD_blind.recalculate then
        pcall(function() G.HUD_blind:recalculate(false) end)
    end
end

---------------------------------------------------------------------------
-- Sigils (the pacts themselves)
---------------------------------------------------------------------------
local function sigil(def)
    def.set = 'Joker'
    def.rarity = 1
    def.atlas = 'abyss_sigils'
    def.cost = 0
    def.eternal_compat = true
    def.perishable_compat = false
    def.blueprint_compat = false
    return SMODS.Joker(def)
end

-- 1. Greed: double score requirement, double money gained
sigil {
    key = 'greed',
    pos = { x = 0, y = 0 },
    config = { extra = {} },
    loc_txt = {
        ['default'] = {
            name = 'Maw of Greed',
            text = {
                '{C:attention}Blind requirements{} are {C:attention}x2{}',
                'All {C:money}money{} gained is {C:money}x2{}',
                '{C:inactive}Abyss Pact - cannot be sold{}',
            },
        },
        ['zh_CN'] = {
            name = '贪婪之胃',
            text = {
                '盲注所需分数 {C:attention}×2{}',
                '所有获得的金钱 {C:money}×2{}',
                '{C:inactive}深渊契约 · 无法出售{}',
            },
        },
    },
}

-- 2/3. Sever: ban 1 or 2 random suits, every scored card scores that many extra times
for _, spec in ipairs { { key = 'sever1', pos = 1, n = 1 }, { key = 'sever2', pos = 2, n = 2 } } do
    local n = spec.n
    sigil {
        key = spec.key,
        pos = { x = spec.pos, y = 0 },
        config = { extra = { banned = {}, n = n } },
        loc_txt = {
            ['default'] = {
                name = 'Severed Arm ' .. (n == 1 and 'I' or 'II'),
                text = {
                    'Bans {C:attention}' .. n .. '{} random suit' .. (n == 1 and '' or 's'),
                    'Their cards are still drawn but {C:attention}score nothing{}',
                    'Every scored card scores {C:attention}#1#{} extra time' .. (n == 1 and '' or 's'),
                    '{C:inactive}Dead suits: {C:inactive}#2#{}',
                },
            },
            ['zh_CN'] = {
                name = n == 1 and '断臂·一' or '断臂·二',
                text = {
                    '随机禁用 {C:attention}' .. n .. '{} 个花色',
                    '这些牌照常抽到，但{C:attention}不计分{}',
                    '每张计分牌额外结算 {C:attention}#1#{} 次',
                    '{C:inactive}已失效：{C:inactive}#2#{}',
                },
            },
        },
        loc_vars = function(self, info_queue, card)
            local banned = (card and card.ability and card.ability.extra
                and card.ability.extra.banned) or {}
            return { vars = { #banned, suit_list_text(banned) } }
        end,
        calculate = function(self, card, context)
            if context.repetition and context.cardarea == G.play then
                local reps = card.ability.extra.reps or #(card.ability.extra.banned or {})
                if reps and reps > 0 then
                    return {
                        message = localize('k_again_ex'),
                        repetitions = reps,
                        card = card,
                    }
                end
            end
        end,
    }
end

-- 4. Burden: harder blinds, one extra hand per round
sigil {
    key = 'burden',
    pos = { x = 3, y = 0 },
    config = { extra = {} },
    loc_txt = {
        ['default'] = {
            name = 'Crushing Burden',
            text = {
                '{C:attention}Blind requirements{} are {C:attention}x1.5{}',
                '{C:attention}+1{} hand per round',
                '{C:inactive}Abyss Pact - cannot be sold{}',
            },
        },
        ['zh_CN'] = {
            name = '重负',
            text = {
                '盲注所需分数 {C:attention}×1.5{}',
                '每回合出牌次数 {C:attention}+1{}',
                '{C:inactive}深渊契约 · 无法出售{}',
            },
        },
    },
}

-- 5. Thrift: no rerolls, shop is half price
sigil {
    key = 'thrift',
    pos = { x = 4, y = 0 },
    config = { extra = {} },
    loc_txt = {
        ['default'] = {
            name = 'Frugal Hunger',
            text = {
                'You can no longer {C:attention}reroll{} the shop',
                'All shop prices are {C:money}halved{}',
                '{C:inactive}Abyss Pact - cannot be sold{}',
            },
        },
        ['zh_CN'] = {
            name = '节食者',
            text = {
                '无法{C:attention}刷新{}商店',
                '商店所有商品价格{C:money}减半{}',
                '{C:inactive}深渊契约 · 无法出售{}',
            },
        },
    },
}

-- 6. Crown: -2 joker slots, but a free Legendary joker at the start
sigil {
    key = 'crown',
    pos = { x = 5, y = 0 },
    config = { extra = {} },
    loc_txt = {
        ['default'] = {
            name = 'Crown of Ruin',
            text = {
                '{C:attention}-2{} Joker slots',
                'Start with a random {C:attention}Legendary{} Joker',
                '{C:inactive}Abyss Pact - cannot be sold{}',
            },
        },
        ['zh_CN'] = {
            name = '残冠',
            text = {
                '小丑栏位 {C:attention}-2{}',
                '开局获得一张随机{C:attention}传奇{}小丑',
                '{C:inactive}深渊契约 · 无法出售{}',
            },
        },
    },
}

-- 7. Single: one card at a time, but it scores three times
sigil {
    key = 'single',
    pos = { x = 6, y = 0 },
    config = { extra = { reps = 2 } },
    loc_txt = {
        ['default'] = {
            name = 'Single Hand',
            text = {
                'You may only select {C:attention}1{} card at a time',
                'Every scored card scores {C:attention}#1#{} extra times',
                '{C:inactive}Abyss Pact - cannot be sold{}',
            },
        },
        ['zh_CN'] = {
            name = '只手',
            text = {
                '每次只能选中 {C:attention}1{} 张牌',
                '每张计分牌额外结算 {C:attention}#1#{} 次',
                '{C:inactive}深渊契约 · 无法出售{}',
            },
        },
    },
    loc_vars = function(self, info_queue, card)
        local reps = (card and card.ability and card.ability.extra and card.ability.extra.reps) or 2
        return { vars = { reps } }
    end,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play then
            local n = card.ability.extra.reps or 0
            if n > 0 then
                return {
                    message = localize('k_again_ex'),
                    repetitions = n,
                    card = card,
                }
            end
        end
    end,
}

---------------------------------------------------------------------------
-- Applying a pact
---------------------------------------------------------------------------
function ABYSS.begin(choice)
    local pact = ABYSS.pacts[choice]
    if not pact then return end
    if ABYSS.active == choice then return end -- never stack the same pact twice

    ABYSS.active = choice
    ABYSS.blind_mult = pact.blind_mult or 1
    ABYSS.money_mult = pact.money_mult or 1

    -- banned suits
    local banned = {}
    if pact.ban_suits and pact.ban_suits > 0 then
        banned = pick_suits(pact.ban_suits)
    end
    ABYSS.banned_suits = banned
    ABYSS.sever_suits = banned

    -- extra hand per round
    if pact.hands then
        G.GAME.starting_params.hands = (G.GAME.starting_params.hands or 4) + pact.hands
        G.GAME.round_resets.hands = (G.GAME.round_resets.hands or 4) + pact.hands
        if G.GAME.current_round and G.GAME.current_round.hands_left then
            G.GAME.current_round.hands_left = G.GAME.current_round.hands_left + pact.hands
        end
    end

    -- no rerolls
    ABYSS.no_reroll = pact.no_reroll or false

    -- shop discount
    if pact.discount then
        G.GAME.discount_percent = math.min(100, (G.GAME.discount_percent or 0) + pact.discount)
        for _, v in pairs(G.I.CARD or {}) do
            if v.set_cost then v:set_cost() end
        end
    end

    -- joker slots
    if pact.joker_slots then
        G.jokers.config.card_limit = math.max(1, G.jokers.config.card_limit + pact.joker_slots)
    end

    -- one card at a time (the hand highlight limit is shared by play and discard)
    if pact.play_limit then
        G.hand.config.highlighted_limit = pact.play_limit
    end

    rescale_current_blind()

    -- spawn the sigil
    G.E_MANAGER:add_event(Event {
        trigger = 'after', delay = 0.4, blocking = false,
        func = function()
            local card = SMODS.add_card { key = choice, set = 'Joker', skip_materialize = true }
            if card then
                card.ability.extra = card.ability.extra or {}
                card.ability.extra.banned = banned
                card.ability.extra.reps = (#banned > 0) and #banned or (pact.reps or 0)
                card:set_eternal(true)
                card:start_materialize()
            end
            -- keep every pact sigil out of shops and boosters (done after the
            -- spawn: create_card refuses to build a banned forced_key)
            G.GAME.banned_keys = G.GAME.banned_keys or {}
            for k in pairs(ABYSS.pacts) do
                G.GAME.banned_keys[k] = true
            end
            return true
        end,
    })

    -- a free Legendary joker
    if pact.legendary then
        G.E_MANAGER:add_event(Event {
            trigger = 'after', delay = 0.55, blocking = false,
            func = function()
                -- G.P_JOKER_RARITY_POOLS holds center objects (or keys, depending
                -- on the smods version), so accept both shapes.
                local function pick_key(rarity)
                    local pool = G.P_JOKER_RARITY_POOLS and G.P_JOKER_RARITY_POOLS[rarity]
                    if not pool or #pool == 0 then return nil end
                    local pick = pseudorandom_element(pool, pseudoseed('abyss_legend' .. rarity))
                    return type(pick) == 'table' and pick.key or pick
                end
                local key = pick_key(4) or pick_key(3)
                if key then
                    local c = SMODS.add_card { key = key, set = 'Joker', skip_materialize = true }
                    if c then c:start_materialize() end
                end
                return true
            end,
        })
    end

    -- mark the banned suits as dead cards (they stay in the deck)
    if #banned > 0 then
        G.E_MANAGER:add_event(Event {
            trigger = 'after', delay = 0.65, blocking = false,
            func = function()
                for _, c in ipairs(G.playing_cards or {}) do
                    ABYSS.debuff_severed(c)
                end
                return true
            end,
        })
    end
end

---------------------------------------------------------------------------
-- Run-select page
---------------------------------------------------------------------------
if SMODS.RunSelectPage then
    SMODS.RunSelectPage {
        key = 'pact',
        type = 'Joker',
        grid_size = { 2, 4 },
        selection_limit = 1,
        automatic_preview = true,
        generate_pool = function(self)
            local pool = {}
            for _, k in ipairs(ABYSS.order) do
                local center = (SMODS.Centers and SMODS.Centers[k]) or (G.P_CENTERS and G.P_CENTERS[k])
                if center then pool[#pool + 1] = center end
            end
            return pool
        end,
        set_default = function(self, choice)
            return nil -- no pact by default: the abyss is optional
        end,
        start_run = function(self, choice)
            ABYSS.begin(choice)
        end,
    }
else
    sendWarnMessage('Abyss: this Steamodded version has no SMODS.RunSelectPage, the pact picker will not appear.', 'Abyss')
end
