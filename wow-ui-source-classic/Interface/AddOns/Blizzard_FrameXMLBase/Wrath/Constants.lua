-- BIG PROBLEM HERE. NOT SAVING REFS
--
-- New constants should be added to this file and other constants
-- deprecated and moved to this file.
--

--
-- Expansion Info
--
MAX_PLAYER_LEVEL_TABLE = {};
MAX_PLAYER_LEVEL_TABLE[LE_EXPANSION_CLASSIC] = 60;
MAX_PLAYER_LEVEL_TABLE[LE_EXPANSION_BURNING_CRUSADE] = 70;
MAX_PLAYER_LEVEL_TABLE[LE_EXPANSION_WRATH_OF_THE_LICH_KING] = 80;
--MAX_PLAYER_LEVEL_TABLE[LE_EXPANSION_CATACLYSM] = 85;
--MAX_PLAYER_LEVEL_TABLE[LE_EXPANSION_MISTS_OF_PANDARIA] = 90;
--MAX_PLAYER_LEVEL_TABLE[LE_EXPANSION_WARLORDS_OF_DRAENOR] = 100;
--MAX_PLAYER_LEVEL_TABLE[LE_EXPANSION_LEGION] = 110;
--MAX_PLAYER_LEVEL_TABLE[LE_EXPANSION_BATTLE_FOR_AZEROTH] = 120;
--MAX_PLAYER_LEVEL_TABLE[LE_EXPANSION_9_0] = 120;
--MAX_PLAYER_LEVEL_TABLE[LE_EXPANSION_10_0] = 120;
--MAX_PLAYER_LEVEL_TABLE[LE_EXPANSION_11_0] = 120;

NPE_TUTORIAL_COMPLETE_LEVEL = 10;


AREA_NAME_FONT_COLOR = CreateColor(1.0, 0.9294, 0.7607);
AREA_DESCRIPTION_FONT_COLOR = HIGHLIGHT_FONT_COLOR;
INVASION_FONT_COLOR = CreateColor(0.78, 1, 0);
INVASION_DESCRIPTION_FONT_COLOR = CreateColor(1, 0.973, 0.035);

FACTION_BAR_COLORS = {
	[1] = {r = 0.8, g = 0.3, b = 0.22},
	[2] = {r = 0.8, g = 0.3, b = 0.22},
	[3] = {r = 0.75, g = 0.27, b = 0},
	[4] = {r = 0.9, g = 0.7, b = 0},
	[5] = {r = 0, g = 0.6, b = 0.1},
	[6] = {r = 0, g = 0.6, b = 0.1},
	[7] = {r = 0, g = 0.6, b = 0.1},
	[8] = {r = 0, g = 0.6, b = 0.1},
};



MATERIAL_TEXT_COLOR_TABLE = {
	["Default"] = {0.18, 0.12, 0.06},
	["Stone"] = {1.0, 1.0, 1.0},
	["Parchment"] = {0.18, 0.12, 0.06},
	["Marble"] = {0, 0, 0},
	["Silver"] = {0.12, 0.12, 0.12},
	["Bronze"] = {0.18, 0.12, 0.06},
	["ParchmentLarge"] = {.141, 0, 0}
};
MATERIAL_TITLETEXT_COLOR_TABLE = {
	["Default"] = {0, 0, 0},
	["Stone"] = {0.93, 0.82, 0},
	["Parchment"] = {0, 0, 0},
	["Marble"] = {0.93, 0.82, 0},
	["Silver"] = {0.93, 0.82, 0},
	["Bronze"] = {0.93, 0.82, 0},
	["ParchmentLarge"] = {.208, 0, 0}
};

FRIENDS_BNET_NAME_COLOR = CreateColor(0.510, 0.773, 1.0);
FRIENDS_BNET_BACKGROUND_COLOR = CreateColor(0, 0.694, 0.941, 0.05);
FRIENDS_WOW_NAME_COLOR = CreateColor(0.996, 0.882, 0.361);
FRIENDS_WOW_BACKGROUND_COLOR = CreateColor(1.0, 0.824, 0.0, 0.05);
FRIENDS_GRAY_COLOR = CreateColor(0.486, 0.518, 0.541);
FRIENDS_OFFLINE_BACKGROUND_COLOR = CreateColor(0.588, 0.588, 0.588, 0.05);
FRIENDS_BNET_NAME_COLOR_CODE = "|cff82c5ff";
FRIENDS_BROADCAST_TIME_COLOR_CODE = "|cff4381a8"
FRIENDS_WOW_NAME_COLOR_CODE = "|cfffde05c";
FRIENDS_OTHER_NAME_COLOR_CODE = "|cff7b8489";


--
-- Class
--
CLASS_SORT_ORDER = {
	"WARRIOR",
	"DEATHKNIGHT",
	"PALADIN",
	--"MONK",
	"PRIEST",
	"SHAMAN",
	"DRUID",
	"ROGUE",
	"MAGE",
	"WARLOCK",
	"HUNTER",
	--"DEMONHUNTER",
};
MAX_CLASSES = #CLASS_SORT_ORDER;

LOCALIZED_CLASS_NAMES_MALE = {};
LOCALIZED_CLASS_NAMES_FEMALE = {};
FillLocalizedClassList(LOCALIZED_CLASS_NAMES_MALE, false);
FillLocalizedClassList(LOCALIZED_CLASS_NAMES_FEMALE, true);




--
-- Glyph
--
SHOW_INSCRIPTION_LEVEL = 15;
INSCRIPTION_AVAILABLE = true;


--
-- Achievement
--
-- Criteria Flags
ACHIEVEMENT_CRITERIA_PROGRESS_BAR		= 0x00000001;
ACHIEVEMENT_CRITERIA_HIDDEN			= 0x00000002;
NUM_ACHIEVEMENT_CRITERIA_FLAGS			= 2;

--
-- Inventory
--


BAG_ITEM_QUALITY_COLORS = {
	[LE_ITEM_QUALITY_COMMON] = {r=0.65882,g=0.65882,b=0.65882},
	[LE_ITEM_QUALITY_UNCOMMON] = {r=0.08235, g=0.70196, b=0},
	[LE_ITEM_QUALITY_RARE] = {r=0, g=0.56863, b=0.94902},
	[LE_ITEM_QUALITY_EPIC] = {r=0.78431, g=0.27059, b=0.98039},
	[LE_ITEM_QUALITY_LEGENDARY] = {r=1, g=0.50196, b=0},
	[LE_ITEM_QUALITY_ARTIFACT] = {r=0.90196, g=0.8, b=0.50196},
	[LE_ITEM_QUALITY_HEIRLOOM] = {r=0, g=0.8, b=1},
	[LE_ITEM_QUALITY_WOW_TOKEN] = {r=0, g=0.8, b=1},
}


-- faction
PLAYER_FACTION_COLORS = { [0] = CreateColor(0.90, 0.05, 0.07), [1] = CreateColor(0.29, 0.33, 0.91) }


-- Guild
MAX_GUILDBANK_TABS = 6;
MAX_BUY_GUILDBANK_TABS = 6;
MAX_GOLD_WITHDRAW = 1000;
MAX_GOLD_WITHDRAW_DIGITS = 9;


-- Quest

MAX_QUESTS = 25;
MAX_OBJECTIVES = 20;
MAX_QUESTLOG_QUESTS = 25;
MAX_WATCHABLE_QUESTS = 25;

WOW_PROJECT_MAINLINE = 1;
WOW_PROJECT_CLASSIC = 2;
WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5;
WOW_PROJECT_WRATH_CLASSIC = 11;
WOW_PROJECT_CATACLYSM_CLASSIC = 14;
WOW_PROJECT_MISTS_CLASSIC = 19;
WOW_PROJECT_ID = WOW_PROJECT_WRATH_CLASSIC;

-- Transmog
ENCHANT_EMPTY_SLOT_FILEDATAID = 134941;
WARDROBE_TOOLTIP_CYCLE_ARROW_ICON = "|TInterface\\Transmogrify\\transmog-tooltip-arrow:12:11:-1:-1|t";
WARDROBE_TOOLTIP_CYCLE_SPACER_ICON = "|TInterface\\Common\\spacer:12:11:-1:-1|t";
WARDROBE_CYCLE_KEY = "TAB";
WARDROBE_PREV_VISUAL_KEY = "LEFT";
WARDROBE_NEXT_VISUAL_KEY = "RIGHT";
WARDROBE_UP_VISUAL_KEY = "UP";
WARDROBE_DOWN_VISUAL_KEY = "DOWN";

TRANSMOG_INVALID_CODES = {
	"NO_ITEM",
	"NOT_SOULBOUND",
	"LEGENDARY",
	"ITEM_TYPE",
	"DESTINATION",
	"MISMATCH",
	"",		-- same item
	"",		-- invalid source
	"",		-- invalid source quality
	"CANNOT_USE",
	"SLOT_FOR_RACE",
	"",		-- no illusion
	"SLOT_FOR_FORM",
}

TRANSMOG_SOURCE_BOSS_DROP = 1;
FIRST_TRANSMOG_COLLECTION_WEAPON_TYPE = Enum.TransmogCollectionType.Wand;
LAST_TRANSMOG_COLLECTION_WEAPON_TYPE = Enum.TransmogCollectionTypeMeta.NumValues - 1;
NO_TRANSMOG_VISUAL_ID = 0;
REMOVE_TRANSMOG_ID = 0;