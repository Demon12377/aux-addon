local Unit =
{
	Name = "Unit",
	Type = "System",

	Functions =
	{
		{
			Name = "GetUnitPowerBarInfo",
			Type = "Function",
			MayReturnNothing = true,

			Arguments =
			{
				{ Name = "unitToken", Type = "UnitToken", Nilable = false },
			},

			Returns =
			{
				{ Name = "info", Type = "UnitPowerBarInfo", Nilable = false },
			},
		},
		{
			Name = "GetUnitPowerBarInfoByID",
			Type = "Function",
			MayReturnNothing = true,

			Arguments =
			{
				{ Name = "barID", Type = "number", Nilable = false },
			},

			Returns =
			{
				{ Name = "info", Type = "UnitPowerBarInfo", Nilable = false },
			},
		},
		{
			Name = "GetUnitPowerBarStrings",
			Type = "Function",

			Arguments =
			{
				{ Name = "unitToken", Type = "UnitToken", Nilable = false },
			},

			Returns =
			{
				{ Name = "name", Type = "cstring", Nilable = true },
				{ Name = "tooltip", Type = "cstring", Nilable = true },
				{ Name = "cost", Type = "cstring", Nilable = true },
			},
		},
		{
			Name = "GetUnitPowerBarStringsByID",
			Type = "Function",

			Arguments =
			{
				{ Name = "barID", Type = "number", Nilable = false },
			},

			Returns =
			{
				{ Name = "name", Type = "cstring", Nilable = true },
				{ Name = "tooltip", Type = "cstring", Nilable = true },
				{ Name = "cost", Type = "cstring", Nilable = true },
			},
		},
		{
			Name = "GetUnitPowerBarTextureInfo",
			Type = "Function",

			Arguments =
			{
				{ Name = "unitToken", Type = "UnitToken", Nilable = false },
				{ Name = "textureIndex", Type = "luaIndex", Nilable = false },
				{ Name = "timerIndex", Type = "luaIndex", Nilable = true },
			},

			Returns =
			{
				{ Name = "texture", Type = "fileID", Nilable = false },
				{ Name = "colorR", Type = "number", Nilable = false },
				{ Name = "colorG", Type = "number", Nilable = false },
				{ Name = "colorB", Type = "number", Nilable = false },
				{ Name = "colorA", Type = "number", Nilable = false },
			},
		},
		{
			Name = "GetUnitPowerBarTextureInfoByID",
			Type = "Function",

			Arguments =
			{
				{ Name = "barID", Type = "number", Nilable = false },
				{ Name = "textureIndex", Type = "luaIndex", Nilable = false },
			},

			Returns =
			{
				{ Name = "texture", Type = "fileID", Nilable = false },
				{ Name = "colorR", Type = "number", Nilable = false },
				{ Name = "colorG", Type = "number", Nilable = false },
				{ Name = "colorB", Type = "number", Nilable = false },
				{ Name = "colorA", Type = "number", Nilable = false },
			},
		},
		{
			Name = "IsPlayerInGuildFromGUID",
			Type = "Function",

			Arguments =
			{
				{ Name = "playerGUID", Type = "WOWGUID", Nilable = false },
			},

			Returns =
			{
				{ Name = "IsInGuild", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "IsUnitModelReadyForUI",
			Type = "Function",

			Arguments =
			{
				{ Name = "unitToken", Type = "UnitToken", Nilable = false },
			},

			Returns =
			{
				{ Name = "isReady", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "SetPortraitTexture",
			Type = "Function",

			Arguments =
			{
				{ Name = "textureObject", Type = "SimpleTexture", Nilable = false },
				{ Name = "unitToken", Type = "UnitToken", Nilable = false },
				{ Name = "disableMasking", Type = "bool", Nilable = false, Default = false },
			},
		},
		{
			Name = "SetPortraitTextureFromCreatureDisplayID",
			Type = "Function",

			Arguments =
			{
				{ Name = "textureObject", Type = "SimpleTexture", Nilable = false },
				{ Name = "creatureDisplayID", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetUnitCursorTexture",
			Type = "Function",

			Arguments =
			{
				{ Name = "textureObject", Type = "SimpleTexture", Nilable = false },
				{ Name = "unit", Type = "UnitToken", Nilable = false },
				{ Name = "style", Type = "CursorStyle", Nilable = true },
				{ Name = "includeLowPriority", Type = "bool", Nilable = true },
			},

			Returns =
			{
				{ Name = "hasCursor", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "ShouldKnowUnitHealth",
			Type = "Function",
			Documentation = { "Whether the player would have been able to know the unit's exact health value in the original game release." },

			Arguments =
			{
				{ Name = "unit", Type = "UnitToken", Nilable = false },
			},

			Returns =
			{
				{ Name = "shouldKnowUnitHealth", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "UnitClass",
			Type = "Function",
			MayReturnNothing = true,

			Arguments =
			{
				{ Name = "unit", Type = "UnitToken", Nilable = false },
			},

			Returns =
			{
				{ Name = "className", Type = "cstring", Nilable = false },
				{ Name = "classFilename", Type = "cstring", Nilable = false },
				{ Name = "classID", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitClassBase",
			Type = "Function",
			MayReturnNothing = true,

			Arguments =
			{
				{ Name = "unit", Type = "UnitToken", Nilable = false },
			},

			Returns =
			{
				{ Name = "classFilename", Type = "cstring", Nilable = false },
				{ Name = "classID", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitCreatureFamily",
			Type = "Function",

			Arguments =
			{
				{ Name = "unit", Type = "UnitToken", Nilable = false },
			},

			Returns =
			{
				{ Name = "name", Type = "cstring", Nilable = false },
				{ Name = "id", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitCreatureType",
			Type = "Function",

			Arguments =
			{
				{ Name = "unit", Type = "UnitToken", Nilable = false },
			},

			Returns =
			{
				{ Name = "name", Type = "cstring", Nilable = false },
				{ Name = "id", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitGetTotalAbsorbs",
			Type = "Function",

			Arguments =
			{
				{ Name = "unit", Type = "UnitToken", Nilable = false },
			},

			Returns =
			{
				{ Name = "result", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitGetTotalHealAbsorbs",
			Type = "Function",

			Arguments =
			{
				{ Name = "unit", Type = "UnitToken", Nilable = false },
			},

			Returns =
			{
				{ Name = "result", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitGroupRolesAssignedEnum",
			Type = "Function",

			Arguments =
			{
				{ Name = "unit", Type = "UnitToken", Nilable = false, Default = "WOWGUID_NULL" },
			},

			Returns =
			{
				{ Name = "result", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitInOtherParty",
			Type = "Function",
			Documentation = { "Checks whether this unit cannot see your party chat because it is in an instance group" },

			Arguments =
			{
				{ Name = "unit", Type = "UnitToken", Nilable = false },
			},

			Returns =
			{
				{ Name = "inOtherParty", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "UnitInPartyIsAI",
			Type = "Function",

			Arguments =
			{
				{ Name = "unit", Type = "UnitToken", Nilable = false, Default = "WOWGUID_NULL" },
			},

			Returns =
			{
				{ Name = "result", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "UnitIsConnected",
			Type = "Function",

			Arguments =
			{
				{ Name = "unit", Type = "UnitToken", Nilable = false },
			},

			Returns =
			{
				{ Name = "isConnected", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "UnitIsGroupAssistant",
			Type = "Function",

			Arguments =
			{
				{ Name = "unit", Type = "UnitToken", Nilable = false },
			},

			Returns =
			{
				{ Name = "isAssistant", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "UnitIsGroupLeader",
			Type = "Function",

			Arguments =
			{
				{ Name = "unit", Type = "UnitToken", Nilable = false },
				{ Name = "partyCategory", Type = "luaIndex", Nilable = true },
			},

			Returns =
			{
				{ Name = "isLeader", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "UnitIsOwnerOrControllerOfUnit",
			Type = "Function",

			Arguments =
			{
				{ Name = "controllingUnit", Type = "UnitToken", Nilable = false },
				{ Name = "controlledUnit", Type = "UnitToken", Nilable = false },
			},

			Returns =
			{
				{ Name = "unitIsOwnerOrControllerOfUnit", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "UnitLeadsAnyGroup",
			Type = "Function",

			Arguments =
			{
				{ Name = "unit", Type = "UnitToken", Nilable = false },
			},

			Returns =
			{
				{ Name = "isLeader", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "UnitNumPowerBarTimers",
			Type = "Function",

			Arguments =
			{
				{ Name = "unit", Type = "UnitToken", Nilable = false },
			},

			Returns =
			{
				{ Name = "result", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitOwnerGUID",
			Type = "Function",

			Arguments =
			{
				{ Name = "unit", Type = "UnitToken", Nilable = false },
			},

			Returns =
			{
				{ Name = "ownerGUID", Type = "WOWGUID", Nilable = false },
			},
		},
		{
			Name = "UnitPower",
			Type = "Function",

			Arguments =
			{
				{ Name = "unitToken", Type = "UnitToken", Nilable = false },
				{ Name = "powerType", Type = "PowerType", Nilable = true },
				{ Name = "unmodified", Type = "bool", Nilable = false, Default = false },
			},

			Returns =
			{
				{ Name = "power", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitPowerBarID",
			Type = "Function",

			Arguments =
			{
				{ Name = "unitToken", Type = "UnitToken", Nilable = false },
			},

			Returns =
			{
				{ Name = "barID", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitPowerBarTimerInfo",
			Type = "Function",
			MayReturnNothing = true,

			Arguments =
			{
				{ Name = "unit", Type = "UnitToken", Nilable = false },
				{ Name = "index", Type = "luaIndex", Nilable = false, Default = 0 },
			},

			Returns =
			{
				{ Name = "duration", Type = "number", Nilable = false },
				{ Name = "expiration", Type = "number", Nilable = false },
				{ Name = "barID", Type = "number", Nilable = false },
				{ Name = "auraID", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitPowerDisplayMod",
			Type = "Function",

			Arguments =
			{
				{ Name = "powerType", Type = "PowerType", Nilable = false },
			},

			Returns =
			{
				{ Name = "displayMod", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitPowerMax",
			Type = "Function",

			Arguments =
			{
				{ Name = "unitToken", Type = "UnitToken", Nilable = false },
				{ Name = "powerType", Type = "PowerType", Nilable = true },
				{ Name = "unmodified", Type = "bool", Nilable = false, Default = false },
			},

			Returns =
			{
				{ Name = "maxPower", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitSex",
			Type = "Function",

			Arguments =
			{
				{ Name = "unit", Type = "UnitToken", Nilable = false },
			},

			Returns =
			{
				{ Name = "sex", Type = "number", Nilable = true },
			},
		},
		{
			Name = "UnitSpellHaste",
			Type = "Function",

			Arguments =
			{
				{ Name = "unit", Type = "UnitToken", Nilable = false },
			},

			Returns =
			{
				{ Name = "result", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitTokenFromGUID",
			Type = "Function",

			Arguments =
			{
				{ Name = "unitGUID", Type = "WOWGUID", Nilable = false },
			},

			Returns =
			{
				{ Name = "unitToken", Type = "string", Nilable = true },
			},
		},
	},

	Events =
	{
		{
			Name = "ActivePlayerSpecializationChanged",
			Type = "Event",
			LiteralName = "ACTIVE_PLAYER_SPECIALIZATION_CHANGED",
		},
		{
			Name = "ArenaCooldownsUpdate",
			Type = "Event",
			LiteralName = "ARENA_COOLDOWNS_UPDATE",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "ArenaCrowdControlSpellUpdate",
			Type = "Event",
			LiteralName = "ARENA_CROWD_CONTROL_SPELL_UPDATE",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
				{ Name = "spellID", Type = "number", Nilable = false },
				{ Name = "itemID", Type = "number", Nilable = false },
			},
		},
		{
			Name = "AutofollowBegin",
			Type = "Event",
			LiteralName = "AUTOFOLLOW_BEGIN",
			Payload =
			{
				{ Name = "name", Type = "cstring", Nilable = false },
			},
		},
		{
			Name = "AutofollowEnd",
			Type = "Event",
			LiteralName = "AUTOFOLLOW_END",
		},
		{
			Name = "CancelSummon",
			Type = "Event",
			LiteralName = "CANCEL_SUMMON",
		},
		{
			Name = "ComboTargetChanged",
			Type = "Event",
			LiteralName = "COMBO_TARGET_CHANGED",
		},
		{
			Name = "ConfirmBinder",
			Type = "Event",
			LiteralName = "CONFIRM_BINDER",
			Payload =
			{
				{ Name = "areaName", Type = "cstring", Nilable = false },
			},
		},
		{
			Name = "ConfirmSummon",
			Type = "Event",
			LiteralName = "CONFIRM_SUMMON",
			Payload =
			{
				{ Name = "summonReason", Type = "number", Nilable = false },
				{ Name = "skippingStartExperience", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "EclipseDirectionChange",
			Type = "Event",
			LiteralName = "ECLIPSE_DIRECTION_CHANGE",
			Payload =
			{
				{ Name = "direction", Type = "cstring", Nilable = false },
			},
		},
		{
			Name = "HearthstoneBound",
			Type = "Event",
			LiteralName = "HEARTHSTONE_BOUND",
		},
		{
			Name = "IncomingResurrectChanged",
			Type = "Event",
			LiteralName = "INCOMING_RESURRECT_CHANGED",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "KnownTitlesUpdate",
			Type = "Event",
			LiteralName = "KNOWN_TITLES_UPDATE",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "LocalplayerPetRenamed",
			Type = "Event",
			LiteralName = "LOCALPLAYER_PET_RENAMED",
		},
		{
			Name = "MirrorTimerPause",
			Type = "Event",
			LiteralName = "MIRROR_TIMER_PAUSE",
			Payload =
			{
				{ Name = "timerName", Type = "cstring", Nilable = false },
				{ Name = "paused", Type = "number", Nilable = false },
			},
		},
		{
			Name = "MirrorTimerStart",
			Type = "Event",
			LiteralName = "MIRROR_TIMER_START",
			Payload =
			{
				{ Name = "timerName", Type = "cstring", Nilable = false },
				{ Name = "value", Type = "number", Nilable = false },
				{ Name = "maxValue", Type = "number", Nilable = false },
				{ Name = "scale", Type = "number", Nilable = false },
				{ Name = "paused", Type = "number", Nilable = false },
				{ Name = "timerLabel", Type = "cstring", Nilable = false },
			},
		},
		{
			Name = "MirrorTimerStop",
			Type = "Event",
			LiteralName = "MIRROR_TIMER_STOP",
			Payload =
			{
				{ Name = "timerName", Type = "cstring", Nilable = false },
			},
		},
		{
			Name = "NeutralFactionSelectResult",
			Type = "Event",
			LiteralName = "NEUTRAL_FACTION_SELECT_RESULT",
			Payload =
			{
				{ Name = "success", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "ObjectEnteredAOI",
			Type = "Event",
			LiteralName = "OBJECT_ENTERED_AOI",
			Payload =
			{
				{ Name = "guid", Type = "WOWGUID", Nilable = false },
			},
		},
		{
			Name = "ObjectLeftAOI",
			Type = "Event",
			LiteralName = "OBJECT_LEFT_AOI",
			Payload =
			{
				{ Name = "guid", Type = "WOWGUID", Nilable = false },
			},
		},
		{
			Name = "PetBarUpdateUsable",
			Type = "Event",
			LiteralName = "PET_BAR_UPDATE_USABLE",
		},
		{
			Name = "PetUiUpdate",
			Type = "Event",
			LiteralName = "PET_UI_UPDATE",
		},
		{
			Name = "PlayerCanGlideChanged",
			Type = "Event",
			LiteralName = "PLAYER_CAN_GLIDE_CHANGED",
			Payload =
			{
				{ Name = "canGlide", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "PlayerDamageDoneMods",
			Type = "Event",
			LiteralName = "PLAYER_DAMAGE_DONE_MODS",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "PlayerEnterCombat",
			Type = "Event",
			LiteralName = "PLAYER_ENTER_COMBAT",
		},
		{
			Name = "PlayerFarsightFocusChanged",
			Type = "Event",
			LiteralName = "PLAYER_FARSIGHT_FOCUS_CHANGED",
		},
		{
			Name = "PlayerFlagsChanged",
			Type = "Event",
			LiteralName = "PLAYER_FLAGS_CHANGED",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "PlayerFocusChanged",
			Type = "Event",
			LiteralName = "PLAYER_FOCUS_CHANGED",
		},
		{
			Name = "PlayerImpulseApplied",
			Type = "Event",
			LiteralName = "PLAYER_IMPULSE_APPLIED",
		},
		{
			Name = "PlayerIsGlidingChanged",
			Type = "Event",
			LiteralName = "PLAYER_IS_GLIDING_CHANGED",
			Payload =
			{
				{ Name = "isGliding", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "PlayerLeaveCombat",
			Type = "Event",
			LiteralName = "PLAYER_LEAVE_COMBAT",
		},
		{
			Name = "PlayerLevelChanged",
			Type = "Event",
			LiteralName = "PLAYER_LEVEL_CHANGED",
			Payload =
			{
				{ Name = "oldLevel", Type = "number", Nilable = false },
				{ Name = "newLevel", Type = "number", Nilable = false },
			},
		},
		{
			Name = "PlayerLevelUp",
			Type = "Event",
			LiteralName = "PLAYER_LEVEL_UP",
			Payload =
			{
				{ Name = "level", Type = "number", Nilable = false },
				{ Name = "healthDelta", Type = "number", Nilable = false },
				{ Name = "powerDelta", Type = "number", Nilable = false },
				{ Name = "numNewTalents", Type = "number", Nilable = false },
				{ Name = "numNewPvpTalentSlots", Type = "number", Nilable = false },
				{ Name = "strengthDelta", Type = "number", Nilable = false },
				{ Name = "agilityDelta", Type = "number", Nilable = false },
				{ Name = "staminaDelta", Type = "number", Nilable = false },
				{ Name = "intellectDelta", Type = "number", Nilable = false },
				{ Name = "spiritDelta", Type = "number", Nilable = false },
			},
		},
		{
			Name = "PlayerMaxLevelUpdate",
			Type = "Event",
			LiteralName = "PLAYER_MAX_LEVEL_UPDATE",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "PlayerMountDisplayChanged",
			Type = "Event",
			LiteralName = "PLAYER_MOUNT_DISPLAY_CHANGED",
		},
		{
			Name = "PlayerPvpKillsChanged",
			Type = "Event",
			LiteralName = "PLAYER_PVP_KILLS_CHANGED",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "PlayerPvpRankChanged",
			Type = "Event",
			LiteralName = "PLAYER_PVP_RANK_CHANGED",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "PlayerRegenDisabled",
			Type = "Event",
			LiteralName = "PLAYER_REGEN_DISABLED",
		},
		{
			Name = "PlayerRegenEnabled",
			Type = "Event",
			LiteralName = "PLAYER_REGEN_ENABLED",
		},
		{
			Name = "PlayerSoftEnemyChanged",
			Type = "Event",
			LiteralName = "PLAYER_SOFT_ENEMY_CHANGED",
		},
		{
			Name = "PlayerSoftFriendChanged",
			Type = "Event",
			LiteralName = "PLAYER_SOFT_FRIEND_CHANGED",
		},
		{
			Name = "PlayerSoftInteractChanged",
			Type = "Event",
			LiteralName = "PLAYER_SOFT_INTERACT_CHANGED",
			Payload =
			{
				{ Name = "oldTarget", Type = "WOWGUID", Nilable = false },
				{ Name = "newTarget", Type = "WOWGUID", Nilable = false },
			},
		},
		{
			Name = "PlayerSoftTargetInteraction",
			Type = "Event",
			LiteralName = "PLAYER_SOFT_TARGET_INTERACTION",
		},
		{
			Name = "PlayerSpecializationChanged",
			Type = "Event",
			LiteralName = "PLAYER_SPECIALIZATION_CHANGED",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "PlayerStartedLooking",
			Type = "Event",
			LiteralName = "PLAYER_STARTED_LOOKING",
		},
		{
			Name = "PlayerStartedMoving",
			Type = "Event",
			LiteralName = "PLAYER_STARTED_MOVING",
		},
		{
			Name = "PlayerStartedTurning",
			Type = "Event",
			LiteralName = "PLAYER_STARTED_TURNING",
		},
		{
			Name = "PlayerStoppedLooking",
			Type = "Event",
			LiteralName = "PLAYER_STOPPED_LOOKING",
		},
		{
			Name = "PlayerStoppedMoving",
			Type = "Event",
			LiteralName = "PLAYER_STOPPED_MOVING",
		},
		{
			Name = "PlayerStoppedTurning",
			Type = "Event",
			LiteralName = "PLAYER_STOPPED_TURNING",
		},
		{
			Name = "PlayerTargetChanged",
			Type = "Event",
			LiteralName = "PLAYER_TARGET_CHANGED",
		},
		{
			Name = "PlayerTargetSetAttacking",
			Type = "Event",
			LiteralName = "PLAYER_TARGET_SET_ATTACKING",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "PlayerTrialXpUpdate",
			Type = "Event",
			LiteralName = "PLAYER_TRIAL_XP_UPDATE",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "PlayerUpdateResting",
			Type = "Event",
			LiteralName = "PLAYER_UPDATE_RESTING",
		},
		{
			Name = "PlayerXpUpdate",
			Type = "Event",
			LiteralName = "PLAYER_XP_UPDATE",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "PortraitsUpdated",
			Type = "Event",
			LiteralName = "PORTRAITS_UPDATED",
		},
		{
			Name = "PvpTimerUpdate",
			Type = "Event",
			LiteralName = "PVP_TIMER_UPDATE",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "RunePowerUpdate",
			Type = "Event",
			LiteralName = "RUNE_POWER_UPDATE",
			Payload =
			{
				{ Name = "runeIndex", Type = "number", Nilable = false },
				{ Name = "added", Type = "bool", Nilable = true },
			},
		},
		{
			Name = "RuneTypeUpdate",
			Type = "Event",
			LiteralName = "RUNE_TYPE_UPDATE",
			Payload =
			{
				{ Name = "runeIndex", Type = "number", Nilable = false },
			},
		},
		{
			Name = "ShowFactionSelectUi",
			Type = "Event",
			LiteralName = "SHOW_FACTION_SELECT_UI",
		},
		{
			Name = "SpellConfirmationPrompt",
			Type = "Event",
			LiteralName = "SPELL_CONFIRMATION_PROMPT",
			Payload =
			{
				{ Name = "spellID", Type = "number", Nilable = false },
				{ Name = "effectValue", Type = "number", Nilable = false },
				{ Name = "message", Type = "cstring", Nilable = false },
				{ Name = "duration", Type = "number", Nilable = false },
				{ Name = "currencyTypesID", Type = "number", Nilable = false },
				{ Name = "currencyCost", Type = "number", Nilable = false },
				{ Name = "currentDifficulty", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SpellConfirmationTimeout",
			Type = "Event",
			LiteralName = "SPELL_CONFIRMATION_TIMEOUT",
			Payload =
			{
				{ Name = "spellID", Type = "number", Nilable = false },
				{ Name = "effectValue", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitAbsorbAmountChanged",
			Type = "Event",
			LiteralName = "UNIT_ABSORB_AMOUNT_CHANGED",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitAttack",
			Type = "Event",
			LiteralName = "UNIT_ATTACK",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitAttackPower",
			Type = "Event",
			LiteralName = "UNIT_ATTACK_POWER",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitAttackSpeed",
			Type = "Event",
			LiteralName = "UNIT_ATTACK_SPEED",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitCheatToggleEvent",
			Type = "Event",
			LiteralName = "UNIT_CHEAT_TOGGLE_EVENT",
		},
		{
			Name = "UnitClassificationChanged",
			Type = "Event",
			LiteralName = "UNIT_CLASSIFICATION_CHANGED",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitCombat",
			Type = "Event",
			LiteralName = "UNIT_COMBAT",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
				{ Name = "event", Type = "cstring", Nilable = false },
				{ Name = "flagText", Type = "cstring", Nilable = false },
				{ Name = "amount", Type = "number", Nilable = false },
				{ Name = "schoolMask", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitConnection",
			Type = "Event",
			LiteralName = "UNIT_CONNECTION",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
				{ Name = "isConnected", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "UnitDamage",
			Type = "Event",
			LiteralName = "UNIT_DAMAGE",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitDefense",
			Type = "Event",
			LiteralName = "UNIT_DEFENSE",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitDisplaypower",
			Type = "Event",
			LiteralName = "UNIT_DISPLAYPOWER",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitDistanceCheckUpdate",
			Type = "Event",
			LiteralName = "UNIT_DISTANCE_CHECK_UPDATE",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
				{ Name = "isInDistance", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "UnitFaction",
			Type = "Event",
			LiteralName = "UNIT_FACTION",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitFlags",
			Type = "Event",
			LiteralName = "UNIT_FLAGS",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitFormChanged",
			Type = "Event",
			LiteralName = "UNIT_FORM_CHANGED",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitHappiness",
			Type = "Event",
			LiteralName = "UNIT_HAPPINESS",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitHealAbsorbAmountChanged",
			Type = "Event",
			LiteralName = "UNIT_HEAL_ABSORB_AMOUNT_CHANGED",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitHealPrediction",
			Type = "Event",
			LiteralName = "UNIT_HEAL_PREDICTION",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitHealth",
			Type = "Event",
			LiteralName = "UNIT_HEALTH",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitHealthFrequent",
			Type = "Event",
			LiteralName = "UNIT_HEALTH_FREQUENT",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitInRangeUpdate",
			Type = "Event",
			LiteralName = "UNIT_IN_RANGE_UPDATE",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
				{ Name = "isInRange", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "UnitInventoryChanged",
			Type = "Event",
			LiteralName = "UNIT_INVENTORY_CHANGED",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitLevel",
			Type = "Event",
			LiteralName = "UNIT_LEVEL",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitMana",
			Type = "Event",
			LiteralName = "UNIT_MANA",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitMaxHealthModifiersChanged",
			Type = "Event",
			LiteralName = "UNIT_MAX_HEALTH_MODIFIERS_CHANGED",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
				{ Name = "percentMaxHealthAdjusted", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitMaxhealth",
			Type = "Event",
			LiteralName = "UNIT_MAXHEALTH",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitMaxpower",
			Type = "Event",
			LiteralName = "UNIT_MAXPOWER",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
				{ Name = "powerType", Type = "cstring", Nilable = false },
			},
		},
		{
			Name = "UnitModelChanged",
			Type = "Event",
			LiteralName = "UNIT_MODEL_CHANGED",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitNameUpdate",
			Type = "Event",
			LiteralName = "UNIT_NAME_UPDATE",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitOtherPartyChanged",
			Type = "Event",
			LiteralName = "UNIT_OTHER_PARTY_CHANGED",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitPet",
			Type = "Event",
			LiteralName = "UNIT_PET",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitPetExperience",
			Type = "Event",
			LiteralName = "UNIT_PET_EXPERIENCE",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitPetTrainingPoints",
			Type = "Event",
			LiteralName = "UNIT_PET_TRAINING_POINTS",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitPhase",
			Type = "Event",
			LiteralName = "UNIT_PHASE",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitPortraitUpdate",
			Type = "Event",
			LiteralName = "UNIT_PORTRAIT_UPDATE",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitPowerBarHide",
			Type = "Event",
			LiteralName = "UNIT_POWER_BAR_HIDE",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitPowerBarShow",
			Type = "Event",
			LiteralName = "UNIT_POWER_BAR_SHOW",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitPowerBarTimerUpdate",
			Type = "Event",
			LiteralName = "UNIT_POWER_BAR_TIMER_UPDATE",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitPowerFrequent",
			Type = "Event",
			LiteralName = "UNIT_POWER_FREQUENT",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
				{ Name = "powerType", Type = "cstring", Nilable = false },
			},
		},
		{
			Name = "UnitPowerUpdate",
			Type = "Event",
			LiteralName = "UNIT_POWER_UPDATE",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
				{ Name = "powerType", Type = "cstring", Nilable = false },
			},
		},
		{
			Name = "UnitQuestLogChanged",
			Type = "Event",
			LiteralName = "UNIT_QUEST_LOG_CHANGED",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitRangedAttackPower",
			Type = "Event",
			LiteralName = "UNIT_RANGED_ATTACK_POWER",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitRangeddamage",
			Type = "Event",
			LiteralName = "UNIT_RANGEDDAMAGE",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitResistances",
			Type = "Event",
			LiteralName = "UNIT_RESISTANCES",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitSpellHaste",
			Type = "Event",
			LiteralName = "UNIT_SPELL_HASTE",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitSpellcastChannelStart",
			Type = "Event",
			LiteralName = "UNIT_SPELLCAST_CHANNEL_START",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
				{ Name = "castGUID", Type = "WOWGUID", Nilable = false },
				{ Name = "spellID", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitSpellcastChannelStop",
			Type = "Event",
			LiteralName = "UNIT_SPELLCAST_CHANNEL_STOP",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
				{ Name = "castGUID", Type = "WOWGUID", Nilable = false },
				{ Name = "spellID", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitSpellcastChannelUpdate",
			Type = "Event",
			LiteralName = "UNIT_SPELLCAST_CHANNEL_UPDATE",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
				{ Name = "castGUID", Type = "WOWGUID", Nilable = false },
				{ Name = "spellID", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitSpellcastDelayed",
			Type = "Event",
			LiteralName = "UNIT_SPELLCAST_DELAYED",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
				{ Name = "castGUID", Type = "WOWGUID", Nilable = false },
				{ Name = "spellID", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitSpellcastFailed",
			Type = "Event",
			LiteralName = "UNIT_SPELLCAST_FAILED",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
				{ Name = "castGUID", Type = "WOWGUID", Nilable = false },
				{ Name = "spellID", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitSpellcastFailedQuiet",
			Type = "Event",
			LiteralName = "UNIT_SPELLCAST_FAILED_QUIET",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
				{ Name = "castGUID", Type = "WOWGUID", Nilable = false },
				{ Name = "spellID", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitSpellcastInterrupted",
			Type = "Event",
			LiteralName = "UNIT_SPELLCAST_INTERRUPTED",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
				{ Name = "castGUID", Type = "WOWGUID", Nilable = false },
				{ Name = "spellID", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitSpellcastInterruptible",
			Type = "Event",
			LiteralName = "UNIT_SPELLCAST_INTERRUPTIBLE",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitSpellcastNotInterruptible",
			Type = "Event",
			LiteralName = "UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitSpellcastStart",
			Type = "Event",
			LiteralName = "UNIT_SPELLCAST_START",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
				{ Name = "castGUID", Type = "WOWGUID", Nilable = false },
				{ Name = "spellID", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitSpellcastStop",
			Type = "Event",
			LiteralName = "UNIT_SPELLCAST_STOP",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
				{ Name = "castGUID", Type = "WOWGUID", Nilable = false },
				{ Name = "spellID", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitSpellcastSucceeded",
			Type = "Event",
			LiteralName = "UNIT_SPELLCAST_SUCCEEDED",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
				{ Name = "castGUID", Type = "WOWGUID", Nilable = false },
				{ Name = "spellID", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitStats",
			Type = "Event",
			LiteralName = "UNIT_STATS",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitTarget",
			Type = "Event",
			LiteralName = "UNIT_TARGET",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitTargetableChanged",
			Type = "Event",
			LiteralName = "UNIT_TARGETABLE_CHANGED",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitThreatListUpdate",
			Type = "Event",
			LiteralName = "UNIT_THREAT_LIST_UPDATE",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UnitThreatSituationUpdate",
			Type = "Event",
			LiteralName = "UNIT_THREAT_SITUATION_UPDATE",
			Payload =
			{
				{ Name = "unitTarget", Type = "UnitToken", Nilable = false },
			},
		},
		{
			Name = "UpdateExhaustion",
			Type = "Event",
			LiteralName = "UPDATE_EXHAUSTION",
		},
		{
			Name = "UpdateMouseoverUnit",
			Type = "Event",
			LiteralName = "UPDATE_MOUSEOVER_UNIT",
		},
		{
			Name = "UpdateStealth",
			Type = "Event",
			LiteralName = "UPDATE_STEALTH",
		},
		{
			Name = "VehicleAngleUpdate",
			Type = "Event",
			LiteralName = "VEHICLE_ANGLE_UPDATE",
			Payload =
			{
				{ Name = "normalizedPitch", Type = "number", Nilable = false },
				{ Name = "radians", Type = "number", Nilable = false },
			},
		},
	},

	Tables =
	{
		{
			Name = "UnitCreatureFamilyResult",
			Type = "Structure",
			Fields =
			{
				{ Name = "name", Type = "cstring", Nilable = false },
				{ Name = "id", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitCreatureTypeResult",
			Type = "Structure",
			Fields =
			{
				{ Name = "name", Type = "cstring", Nilable = false },
				{ Name = "id", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UnitPowerBarInfo",
			Type = "Structure",
			Fields =
			{
				{ Name = "ID", Type = "number", Nilable = false },
				{ Name = "barType", Type = "number", Nilable = false },
				{ Name = "minPower", Type = "number", Nilable = false },
				{ Name = "startInset", Type = "number", Nilable = false },
				{ Name = "endInset", Type = "number", Nilable = false },
				{ Name = "smooth", Type = "bool", Nilable = false },
				{ Name = "hideFromOthers", Type = "bool", Nilable = false },
				{ Name = "showOnRaid", Type = "bool", Nilable = false },
				{ Name = "opaqueSpark", Type = "bool", Nilable = false },
				{ Name = "opaqueFlash", Type = "bool", Nilable = false },
				{ Name = "anchorTop", Type = "bool", Nilable = false },
				{ Name = "forcePercentage", Type = "bool", Nilable = false },
				{ Name = "sparkUnderFrame", Type = "bool", Nilable = false },
				{ Name = "flashAtMinPower", Type = "bool", Nilable = false },
				{ Name = "fractionalCounter", Type = "bool", Nilable = false },
				{ Name = "animateNumbers", Type = "bool", Nilable = false },
				{ Name = "attachTooltipToBar", Type = "bool", Nilable = false },
			},
		},
	},
};

APIDocumentation:AddDocumentationTable(Unit);