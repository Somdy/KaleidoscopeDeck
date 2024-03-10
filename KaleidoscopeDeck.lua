--- STEAMODDED HEADER
--- MOD_NAME: Kaleidoscope Deck
--- MOD_ID: Kaleideck
--- MOD_AUTHOR: [Somdy]
--- MOD_DESCRIPTION: Adds an enhanced deck with different seals and editions.

----------------------------------------------
------------MOD CODE -------------------------

local MOD_ID = "Kaleideck";
local LANGUAGE = "eng";

local deck_loc_en = {
    ["name"] = "Kaleidoscope Deck",
    ["text"] = {
        [1] = "Random cards in deck",
        [2] = "are {C:attention}Enhanced{}",
        [3] = "with different {C:attention}Seals{} and {C:attention}Editions{}",
        [4] = "Start run with",
        [5] = "{C:attention}Eternal{} {C:red,T:j_kaleidojoker}Kaleidojoker{}"
    }
};
local deck_loc_chs = {
    ["name"] = "万花筒牌组",
    ["text"] = {
        [1] = "牌组中随机牌已{C:attention}增强{}",
        [2] = "并有不同的{C:attention}蜡封{}和{C:attention}版本{}",
        [3] = "开局带有{C:attention}永恒{}的{C:red,T:j_kaleidojoker}万花筒小丑{}"
    }
};
local deck_loc = {
    ["eng"] = deck_loc_en,
    ["chs"] = deck_loc_chs,
}
local kaleideck = SMODS.Deck:new("Kaleidoscope Deck", "kaleidoscope_deck", { kaleidscope = true }, { x = 0, y = 5 },
    deck_loc[LANGUAGE]);
kaleideck:register();

function SMODS.INIT.KaleidoscopeDeck()
    local joker_loc_en = {
        ["name"] = "Kaleidojoker",
        ["text"] = {
            [1] = "{X:red,C:white}X0.25{} Mult if played",
            [2] = "hand contains less",
            [3] = "than {C:attention}4{} cards!"
        }
    };
    local joker_loc_chs = {
        ["name"] = "万花筒小丑",
        ["text"] = {
            [1] = "如果打出的牌",
            [2] = "少于{C:attention}4{}张，",
            [3] = "则{X:red,C:white}X0.25{}倍率！"
        }
    };
    local joker_loc = {
        ["eng"] = joker_loc_en,
        ["chs"] = joker_loc_chs,
    }
    local j_kaleidojoker = SMODS.Joker:new("Kaleidojoker", "kaleidojoker", { extra = { least_cards = 4, x_mult = 0.25 } },
        { x = 0, y = 0 }, joker_loc[LANGUAGE], 1, 1, true, true, false, true);
    j_kaleidojoker:register();

    local kaleideck_mod = SMODS.findModByID(MOD_ID);

    local joker_sprite = SMODS.Sprite:new("j_kaleidojoker", kaleideck_mod.path, "j_kaleidojoker.png", 71, 95,
        "asset_atli");
    joker_sprite:register();

    local enhancer_sprite = SMODS.Sprite:new("centers", kaleideck_mod.path, "Enhancers.png", 71, 95, "asset_atli");
    enhancer_sprite:register();
end

local function pseduorng(min, max)
    local seed = G.GAME.pseudorandom.seed;
    return pseudorandom(seed, min, max);
end

local function return_random_seal()
    local seed = G.GAME.pseudorandom.seed .. "sealrng";
    local seal = pseudorandom(seed, 0, 3);
    if seal == 0 then
        return { name = "Red", order = 3 };
    elseif seal == 1 then
        return { name = "Gold", order = 4 };
    elseif seal == 2 then
        return { name = "Blue", order = 1 };
    else
        return { name = "Purple", order = 2 };
    end
end

local function return_random_enhancement()
    local enhancements = {
        { id = G.P_CENTERS.m_glass, order = 4 },
        { id = G.P_CENTERS.m_bonus, order = 1 },
        { id = G.P_CENTERS.m_mult,  order = 3 },
        { id = G.P_CENTERS.m_wild,  order = 1 },
        { id = G.P_CENTERS.m_steel, order = 2 },
        { id = G.P_CENTERS.m_stone, order = 1 },
        { id = G.P_CENTERS.m_gold,  order = 1 },
        { id = G.P_CENTERS.m_lucky, order = 2 }
    };
    local seed = G.GAME.pseudorandom.seed .. "enhancementrng";
    local e_length = #enhancements;
    local e = pseudorandom(seed, 1, e_length);
    return enhancements[e];
end

-- apply changes to starting deck
local back_apply_to_run_ref = Back.apply_to_run;
function Back.apply_to_run(deck)
    back_apply_to_run_ref(deck);
    if deck.effect.config.kaleidscope then
        G.E_MANAGER:add_event(Event({
            func = function()
                -- modify starting cards
                local applied_buffs = 0;
                for i = #G.playing_cards, 1, -1 do
                    local card = G.playing_cards[i];
                    local suit = card.base.suit;
                    sendDebugMessage(suit .. card.base.id);

                    -- enhance card
                    local apply_enhancement = pseduorng(0, 10 + applied_buffs) <= 4;
                    if apply_enhancement then
                        local enhancement = return_random_enhancement();
                        G.playing_cards[i]:set_ability(enhancement.id, true, false);
                        applied_buffs = applied_buffs + enhancement.order;
                    elseif applied_buffs > 0 then
                        applied_buffs = applied_buffs - 1;
                    end

                    -- add seal to card
                    local apply_seal = pseduorng(0, 10 + applied_buffs) <= 4;
                    if apply_seal then
                        local seal_to_add = return_random_seal();
                        G.playing_cards[i]:set_seal(seal_to_add.name, true, true);
                        applied_buffs = applied_buffs + seal_to_add.order;
                    elseif applied_buffs > 0 then
                        applied_buffs = applied_buffs - 1;
                    end

                    -- set random edition
                    local apply_edition = pseduorng(0, 5 + applied_buffs) <= 4;
                    if apply_edition then
                        applied_buffs = applied_buffs + 1;
                        local edition = pseduorng(0, 2);
                        if edition == 0 then
                            G.playing_cards[i]:set_edition({ foil = true }, true, true);
                        elseif edition == 1 then
                            G.playing_cards[i]:set_edition({ polychrome = true }, true, true);
                        elseif edition == 2 then
                            G.playing_cards[i]:set_edition({ holo = true }, true, true);
                        end
                    elseif applied_buffs > 0 then
                        applied_buffs = applied_buffs - 1;
                    end
                end
                -- add joker
                local j_card = create_card("Joker", G.jokers, false, nil, nil, nil, "j_kaleidojoker", nil);
                --j_card:set_eternal(true);
                j_card.ability.eternal = true;
                j_card:add_to_deck();
                G.jokers:emplace(j_card);
                return true;
            end
        }));
    end
end

-- apply Kaleidojoker effect
local card_calculate_joker_ref = Card.calculate_joker;
function Card.calculate_joker(self, context)
    local calculate_joker_ref = card_calculate_joker_ref(self, context);
    -- check if it is Joker calculating and not debuffed
    if self.ability.set == "Joker" and not self.debuff then
        -- this is when Jokers like Half Joker works
        -- for overall cards played and not individual card
        if context.cardarea == G.jokers then
            -- this is when most multi Jokers works
            if context.joker_main then
                if self.ability.name == "Kaleidojoker" then
                    local cards_in_play = #context.full_hand;
                    local least_cards_needed = self.ability.extra.least_cards;
                    -- x0.5 mult if cards less than least needed
                    if cards_in_play < least_cards_needed then
                        return {
                            message = localize { type = 'variable', key = 'a_xmult', vars = { self.ability.extra.x_mult } },
                            Xmult_mod = self.ability.extra.x_mult,
                        };
                    end
                end
            end
        end
    end
    return calculate_joker_ref;
end
