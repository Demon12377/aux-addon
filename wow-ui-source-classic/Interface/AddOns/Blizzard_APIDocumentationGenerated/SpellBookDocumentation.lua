local SpellBook =
{
	Name = "SpellBook",
	Type = "System",
	Namespace = "C_SpellBook",

	Functions =
	{
		{
			Name = "HasPetSpells",
			Type = "Function",
			MayReturnNothing = true,
			Documentation = { "Returns nothing if player has no pet spells" },

			Returns =
			{
				{ Name = "numPetSpells", Type = "number", Nilable = false },
				{ Name = "petNameToken", Type = "string", Nilable = false },
			},
		},
	},

	Events =
	{
		{
			Name = "CurrentSpellCastChanged",
			Type = "Event",
			LiteralName = "CURRENT_SPELL_CAST_CHANGED",
			Payload =
			{
				{ Name = "cancelledCast", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "LearnedSpellInTab",
			Type = "Event",
			LiteralName = "LEARNED_SPELL_IN_TAB",
			Payload =
			{
				{ Name = "spellID", Type = "number", Nilable = false },
				{ Name = "skillInfoIndex", Type = "number", Nilable = false },
				{ Name = "isGuildPerkSpell", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "MaxSpellStartRecoveryOffsetChanged",
			Type = "Event",
			LiteralName = "MAX_SPELL_START_RECOVERY_OFFSET_CHANGED",
			Payload =
			{
				{ Name = "clampedNewQueueWindowMs", Type = "number", Nilable = false },
			},
		},
		{
			Name = "PlayerTotemUpdate",
			Type = "Event",
			LiteralName = "PLAYER_TOTEM_UPDATE",
			Payload =
			{
				{ Name = "totemSlot", Type = "luaIndex", Nilable = false },
			},
		},
		{
			Name = "SpellFlyoutUpdate",
			Type = "Event",
			LiteralName = "SPELL_FLYOUT_UPDATE",
			Payload =
			{
				{ Name = "flyoutID", Type = "number", Nilable = true },
				{ Name = "spellID", Type = "number", Nilable = true },
				{ Name = "isLearned", Type = "bool", Nilable = true },
			},
		},
		{
			Name = "SpellPushedToActionbar",
			Type = "Event",
			LiteralName = "SPELL_PUSHED_TO_ACTIONBAR",
			Payload =
			{
				{ Name = "spellID", Type = "number", Nilable = false },
				{ Name = "slot", Type = "number", Nilable = false },
				{ Name = "page", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SpellPushedToFlyoutOnActionbar",
			Type = "Event",
			LiteralName = "SPELL_PUSHED_TO_FLYOUT_ON_ACTIONBAR",
			Payload =
			{
				{ Name = "spellID", Type = "number", Nilable = false },
				{ Name = "flyoutSlot", Type = "luaIndex", Nilable = false },
				{ Name = "flyoutPage", Type = "luaIndex", Nilable = false },
			},
		},
		{
			Name = "SpellUpdateCharges",
			Type = "Event",
			LiteralName = "SPELL_UPDATE_CHARGES",
		},
		{
			Name = "SpellUpdateCooldown",
			Type = "Event",
			LiteralName = "SPELL_UPDATE_COOLDOWN",
			Payload =
			{
				{ Name = "spellID", Type = "number", Nilable = true, Documentation = { "Can be a base spell or an override spell. A nil value indicates that all cooldowns should be updated, rather than just a specific one." } },
				{ Name = "baseSpellID", Type = "number", Nilable = true, Documentation = { "Will be set to the base spell if the spellID parameter is an override spell." } },
				{ Name = "category", Type = "number", Nilable = true, Documentation = { "If the spellID parameter is set, the cooldown category of the spell. A nil value indicates the spell does not have a cooldown category." } },
				{ Name = "startRecoveryCategory", Type = "number", Nilable = true, Documentation = { "If the spellID parameter is set, the cooldown start recovery category of the spell. A nil value indicates the spell does not have a cooldown start recovery category." } },
			},
		},
		{
			Name = "SpellUpdateIcon",
			Type = "Event",
			LiteralName = "SPELL_UPDATE_ICON",
			Payload =
			{
				{ Name = "spellID", Type = "number", Nilable = true, Documentation = { "Always refers to the base spell. A nil value indicates that all icons should be updated, rather than just a specific one." } },
			},
		},
		{
			Name = "SpellUpdateUsable",
			Type = "Event",
			LiteralName = "SPELL_UPDATE_USABLE",
		},
		{
			Name = "SpellUpdateUses",
			Type = "Event",
			LiteralName = "SPELL_UPDATE_USES",
			Payload =
			{
				{ Name = "spellID", Type = "number", Nilable = false, Documentation = { "Can be a base spell or override spell." } },
				{ Name = "baseSpellID", Type = "number", Nilable = true, Documentation = { "Will be set to the base spell if the spellID parameter is an override spell." } },
			},
		},
		{
			Name = "SpellsChanged",
			Type = "Event",
			LiteralName = "SPELLS_CHANGED",
		},
		{
			Name = "StartAutorepeatSpell",
			Type = "Event",
			LiteralName = "START_AUTOREPEAT_SPELL",
		},
		{
			Name = "StopAutorepeatSpell",
			Type = "Event",
			LiteralName = "STOP_AUTOREPEAT_SPELL",
		},
		{
			Name = "UnitSpellcastSent",
			Type = "Event",
			LiteralName = "UNIT_SPELLCAST_SENT",
			Payload =
			{
				{ Name = "unit", Type = "cstring", Nilable = false },
				{ Name = "target", Type = "cstring", Nilable = false },
				{ Name = "castGUID", Type = "WOWGUID", Nilable = false },
				{ Name = "spellID", Type = "number", Nilable = false },
			},
		},
		{
			Name = "UpdateShapeshiftCooldown",
			Type = "Event",
			LiteralName = "UPDATE_SHAPESHIFT_COOLDOWN",
		},
		{
			Name = "UpdateShapeshiftForm",
			Type = "Event",
			LiteralName = "UPDATE_SHAPESHIFT_FORM",
		},
		{
			Name = "UpdateShapeshiftForms",
			Type = "Event",
			LiteralName = "UPDATE_SHAPESHIFT_FORMS",
		},
		{
			Name = "UpdateShapeshiftUsable",
			Type = "Event",
			LiteralName = "UPDATE_SHAPESHIFT_USABLE",
		},
	},

	Tables =
	{
	},
};

APIDocumentation:AddDocumentationTable(SpellBook);