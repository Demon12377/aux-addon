-- See CharacterServicesFlowMixin for more documentation

CHARACTER_UPGRADE_CREATE_CHARACTER_DATA = nil;

local UPGRADE_BONUS_LEVEL = 60;
local CHARACTERSERVICEINFO_FLAGS_ALLOW_MAX_LEVEL_BOOST = 0x00000002;
CURRENCY_KRW = 3;

local factionLogoTextures = {
	[1]	= "Interface\\Icons\\Inv_Misc_Tournaments_banner_Orc",
	[2]	= "Interface\\Icons\\Achievement_PVP_A_A",
};

local factionLabels = {
	[0] = FACTION_HORDE,
	[1] = FACTION_ALLIANCE,
};

-- TODO: Expose enum to Lua?
FACTION_IDS = {
	["Horde"] = 0,
	["Alliance"] = 1,
};

local factionColors = {
	[FACTION_IDS["Horde"]] = "ffe50d12",
	[FACTION_IDS["Alliance"]] = "ff4a54e8"
};

local stepTextures = {
	[1] = { 0.16601563, 0.23535156, 0.00097656, 0.07812500 },
	[2] = { 0.23730469, 0.30664063, 0.00097656, 0.07812500 },
	[3] = { 0.30859375, 0.37792969, 0.00097656, 0.07812500 },
	[4] = { 0.37988281, 0.44921875, 0.00097656, 0.07812500 },
	[5] = { 0.45117188, 0.52050781, 0.00097656, 0.07812500 },
	[6] = { 0.52246094, 0.59179688, 0.00097656, 0.07812500 },
	[7] = { 0.59375000, 0.66308594, 0.00097656, 0.07812500 },
	[8] = { 0.66503906, 0.73437500, 0.00097656, 0.07812500 },
	[9] = { 0.73632813, 0.80566406, 0.00097656, 0.07812500 },
};

local professionsMap = {
	[164] = CHARACTER_PROFESSION_BLACKSMITHING,
	[165] = CHARACTER_PROFESSION_LEATHERWORKING,
	[171] = CHARACTER_PROFESSION_ALCHEMY,
	[182] = CHARACTER_PROFESSION_HERBALISM,
	[186] = CHARACTER_PROFESSION_MINING,
	[197] = CHARACTER_PROFESSION_TAILORING,
	[202] = CHARACTER_PROFESSION_ENGINEERING,
	[333] = CHARACTER_PROFESSION_ENCHANTING,
	[393] = CHARACTER_PROFESSION_SKINNING,
	[755] = CHARACTER_PROFESSION_JEWELCRAFTING,
	[773] = CHARACTER_PROFESSION_INSCRIPTION,
};

local classDefaultProfessionMap = {
	["WARRIOR"] = "PLATE",
	["PALADIN"] = "PLATE",
	["HUNTER"] = "LEATHERMAIL",
	["ROGUE"] = "LEATHERMAIL",
	["PRIEST"] = "CLOTH",
	["DEATHKNIGHT"] = "PLATE",
	["SHAMAN"] = "LEATHERMAIL",
	["MAGE"] = "CLOTH",
	["WARLOCK"] = "CLOTH",
	["MONK"] = "LEATHERMAIL",
	["DRUID"] = "LEATHERMAIL",
	["DEMONHUNTER"] = "LEATHERMAIL",
};

local defaultProfessions = {
	["PLATE"] = { [1] = 164, [2] = 186 },
	["LEATHERMAIL"] = { [1] = 165, [2] = 393 },
	["CLOTH"] = { [1] = 197, [2] = 333 },
};

StaticPopupDialogs["PRODUCT_ASSIGN_TO_TARGET_FAILED"] = {
	text = BLIZZARD_STORE_INTERNAL_ERROR,
	button1 = OKAY,
	escapeHides = true,
};

StaticPopupDialogs["BOOST_FACTION_CHANGE_IN_PROGRESS"] = {
	text = CHARACTER_BOOST_ERROR_PENDING_FACTION_CHANGE,
	button1 = OKAY,
	escapeHides = true,
};

local CharacterUpgradeCharacterSelectBlock = { FrameName = "CharacterUpgradeSelectCharacterFrame", Back = false, Next = false, Finish = false, AutoAdvance = true, ResultsLabel = SELECT_CHARACTER_RESULTS_LABEL, ActiveLabel = SELECT_CHARACTER_ACTIVE_LABEL, Popup = "BOOST_ALLIED_RACE_HERITAGE_ARMOR_WARNING" };
local CharacterUpgradeFactionSelectBlock = { FrameName = "CharacterUpgradeFactionSelectFrame", Back = true, Next = true, Finish = false, AutoAdvance = true, SkipOnRewind = true, ResultsLabel = SELECT_FACTION_RESULTS_LABEL, ActiveLabel = SELECT_FACTION_ACTIVE_LABEL};
local CharacterUpgradeEndStep = { Back = true, Next = false, Finish = true, HiddenStep = true, SkipOnRewind = true };

CharacterServicesFlowPrototype = {};

CharacterUpgradeFlow = Mixin(
	{
		FinishLabel = CHARACTER_UPGRADE_FINISH_LABEL,

		Steps = {
			[1] = CharacterUpgradeCharacterSelectBlock,
			[2] = CharacterUpgradeFactionSelectBlock,
			[3] = CharacterUpgradeEndStep,
		},
	},
	CharacterServicesFlowMixin
);

function CharacterServicesFlowPrototype:BuildResults(steps)
	if (not self.results) then
		self.results = {};
	end
	wipe(self.results);
	for i = 1, steps do
		for k,v in pairs(self.Steps[i]:GetResult()) do
			self.results[k] = v;
		end
	end
	return self.results;
end

function CharacterServicesFlowPrototype:Rewind(controller)
	local block = self.Steps[self.step];
	local results;
	local wasFromRewind = true;

	if (block.OnRewind) then
		block:OnRewind();
	end

	if (block:IsFinished(wasFromRewind) and not block.SkipOnRewind) then
		if (self.step ~= 1) then
			results = self:BuildResults(self.step - 1);
		end
		self:SetUpBlock(controller, results);
	else
		self:HideBlock(self.step);
		self.step = self.step - 1;
		while ( self.Steps[self.step].SkipOnRewind ) do
			if (self.Steps[self.step].OnRewind) then
				self.Steps[self.step]:OnRewind();
			end
			self:HideBlock(self.step);
			self.step = self.step - 1;
		end
		if (self.step ~= 1) then
			results = self:BuildResults(self.step - 1);
		end
		self:SetUpBlock(controller, results, wasFromRewind);
	end
end

function CharacterServicesFlowPrototype:Restart(controller)
	for i = 1, #self.Steps do
		self:HideBlock(i);
	end
	self.step = 1;
	self:SetUpBlock(controller);
end

local function moveBlock(self, block, offset)
	local extraOffset = block.ExtraOffset or 0;
	local lastNonHiddenStep = self.step - 1;
	while (self.Steps[lastNonHiddenStep].HiddenStep and lastNonHiddenStep >= 1) do
		lastNonHiddenStep = lastNonHiddenStep - 1;
	end
	if (lastNonHiddenStep >= 1) then
		block.frame:SetPoint("TOP", self.Steps[lastNonHiddenStep].frame, "TOP", 0, offset - extraOffset);
	end
end

function CharacterServicesFlowPrototype:SetUpBlock(controller, results, wasFromRewind)
	local block = self.Steps[self.step];
	CharacterServicesMaster_SetCurrentBlock(controller, block, wasFromRewind);
	if (not block.HiddenStep) then
		if (self.step == 1) then
			block.frame:SetPoint("TOP", CharacterServicesMaster, "TOP", -30, 0);
		else
			moveBlock(self, block, -105);
		end
		block.frame.StepNumber:SetTexCoord(unpack(stepTextures[self.step]));
		block.frame:Show();
	end
	block:Initialize(results, wasFromRewind);
	CharacterServicesMaster_Update();
end

function CharacterServicesFlowPrototype:HideBlock(step)
	local block = self.Steps[step];
	if (not block.HiddenStep) then
		block.frame:Hide();
	end
end

function CharacterServicesFlowPrototype:OnHide()
	for i = 1, #self.Steps do
		local block = self.Steps[i];
		if (block.OnHide) then
			block:OnHide();
		end
	end
end

function CharacterServicesFlowPrototype:GetFinishLabel()
	return "";
end

function CharacterUpgradeFlow:SetTarget(data)
	self.data = data;
end

function CharacterUpgradeFlow:SetAutoSelectGuid(guid)
	self.autoSelectGuid = guid;
end

function CharacterUpgradeFlow:GetAutoSelectGuid()
	return self.autoSelectGuid;
end

function CharacterUpgradeFlow:SetTrialBoostGuid(guid)
	self:SetAutoSelectGuid(guid);
	self.isTrialBoost = guid ~= nil;
end

function CharacterUpgradeFlow:IsTrialBoost()
	return self.isTrialBoost;
end

function CharacterUpgradeFlow:IsUnrevoke()
	if self:IsTrialBoost() then
		return false;
	end

	local results = self:BuildResults(self:GetNumSteps());
	if not results.charid then
		-- We haven't chosen a character yet.
		return nil;
	end

	local isRevokedCharacterUpgrade = select(24, GetCharacterInfo(results.charid));
	return isRevokedCharacterUpgrade;
end

function CharacterUpgradeFlow:Initialize(controller)
	CharacterUpgradeSecondChanceWarningFrame.warningAccepted = false;
	CharacterUpgradeSecondChanceWarningFrame:Hide();

	CharacterServicesFlowMixin.Initialize(self, controller);

	self.hasVeteran = nil;
end

function CharacterUpgradeFlow:Rewind(controller)
	self:SetAutoSelectGuid(nil);
	return CharacterServicesFlowMixin.Rewind(self, controller);
end

function CharacterUpgradeFlow:OnHide()
	self:SetAutoSelectGuid(nil);
	return CharacterServicesFlowMixin.OnHide(self);
end

function CharacterUpgradeFlow:OnAdvance()
	local block = self.Steps[self.step];
	if (self.step == 1) then return end;
	if (not block.HiddenStep) then
		local extraOffset = 0;
		if (self.step == 2) then
			extraOffset = 15;
		end
		moveBlock(self, block, -60 - extraOffset);
	end
end

function CharacterUpgradeFlow:Finish(controller)
	local results = self:BuildResults(self:GetNumSteps());
	
	if (not CharacterUpgradeMaxLevelWarningFrame.warningAccepted) then
		local realmName = GetServerName();
		local name, _, _, class, classFileName, _, level, _, _, _, _, _, _, _, _, prof1, prof2, _, _, _, _, isTrialBoost, _, revokedCharacterUpgrade = GetCharacterInfo(results.charid);
		if(level == self.data.level) then -- If character is the target level for this boost
			CharacterUpgradeMaxLevelWarningBackground.ConfirmButton:SetText(self:GetFinishLabel());
			CharacterUpgradeMaxLevelWarningBackground.ConfirmButton:Disable();
			CharacterUpgradeMaxLevelWarningBackground.Text:SetText(CHARACTER_UPGRADE_MAX_LEVEL_POPUP_TEXT:format(self.data.level));
			CharacterUpgradeMaxLevelWarningBackground.CharacterDetails:SetText(CHARACTER_UPGRADE_CONFIRMATION_TEXT:format(name, realmName, RAID_CLASS_COLORS[classFileName].colorStr, class, level, self.data.level));
			CharacterUpgradeMaxLevelWarningFrame:Show();
			return false;
		end
	end

	if (not CharacterUpgradeSecondChanceWarningFrame.warningAccepted and not CharacterUpgradeMaxLevelWarningFrame.warningAccepted) then
		CharacterUpgradeSecondChanceWarningBackground.ConfirmButton:SetText(self:GetFinishLabel());
		CharacterUpgradeSecondChanceWarningBackground.ConfirmButton:Disable();

		if ( self:IsTrialBoost() ) then
			if ( C_StoreSecure.GetCurrencyID() == CURRENCY_KRW ) then
				CharacterUpgradeSecondChanceWarningBackground.Text:SetText(CHARACTER_UPGRADE_KRW_FINISH_TRIAL_BOOST_BUTTON_POPUP_TEXT);
			else
				CharacterUpgradeSecondChanceWarningBackground.Text:SetText(CHARACTER_UPGRADE_FINISH_TRIAL_BOOST_BUTTON_POPUP_TEXT);
			end
		else
			if ( C_StoreSecure.GetCurrencyID() == CURRENCY_KRW ) then
				CharacterUpgradeSecondChanceWarningBackground.Text:SetText(CHARACTER_UPGRADE_KRW_FINISH_BUTTON_POPUP_TEXT);
			else
				CharacterUpgradeSecondChanceWarningBackground.Text:SetText(CHARACTER_UPGRADE_FINISH_BUTTON_POPUP_TEXT:format(self.data.level));
			end
		end

		local realmName = GetServerName();
		local name, _, _, class, classFileName, _, level, _, _, _, _, _, _, _, _, prof1, prof2, _, _, _, _, isTrialBoost, _, revokedCharacterUpgrade = GetCharacterInfo(results.charid);
		CharacterUpgradeSecondChanceWarningBackground.CharacterDetails:SetText(CHARACTER_UPGRADE_CONFIRMATION_TEXT:format(name, realmName, RAID_CLASS_COLORS[classFileName].colorStr, class, level, self.data.level));

		CharacterUpgradeSecondChanceWarningFrame:Show();
		return false;
	end

	if self:IsUnrevoke() then
		local guid = select(15, GetCharacterInfo(results.charid));
		C_CharacterServices.RequestManualUnrevoke(guid);
	else

		if (not results.faction) then
			-- Non neutral character, convert faction group to id.
			results.faction = FACTION_IDS[C_CharacterServices.GetFactionGroupByIndex(results.charid)];
		end
		local guid = select(15, GetCharacterInfo(results.charid));
		if (guid ~= results.playerguid) then
			-- Bail because guid has changed!
			message(CHARACTER_UPGRADE_CHARACTER_LIST_CHANGED_ERROR);
			self:Restart(controller);
			return false;
		end

		self:SetTrialBoostGuid(nil);

		CharacterServicesMaster.pendingGuid = results.playerguid;
		results.spec = 0;
		local raceFilename, _, _, classId = select(3, GetCharacterInfo(GetCharIDFromIndex(results.charid)));
		results.classId = classId;
		results.raceId = C_CharacterCreation.GetRaceIDFromName(raceFilename);
		C_CharacterServices.AssignUpgradeDistribution(results.playerguid, results.faction, results.spec, results.classId, self.data.boostType, results.raceId);
	end
	return true;
end

function CharacterUpgradeFlow:GetFinishLabel()
	-- "Level Up!" is replaced with "Unlock!" when unlocking a trial boost character.
	if self:IsTrialBoost() then
		return CHARACTER_UPGRADE_UNLOCK_TRIAL_CHARACTER_FINISH_LABEL;
	end

	if self:IsUnrevoke() then
		return CHARACTER_UPGRADE_UNREVOKE_CHARACTER_FINISH_LABEL;
	end

	return CharacterServicesFlowMixin.GetFinishLabel(self);
end

local function replaceScripts(button)
	button:SetScript("OnClick", nil);
	button:SetScript("OnDoubleClick", nil);
	button:SetScript("OnDragStart", nil);
	button:SetScript("OnDragStop", nil);
	button:SetScript("OnMouseDown", nil);
	button:SetScript("OnMouseUp", nil);
	button.upButton:SetScript("OnClick", nil);
	button.downButton:SetScript("OnClick", nil);
	button:SetScript("OnEnter", nil);
	button:SetScript("OnLeave", nil);
end

local function resetScripts(button)
	button:SetScript("OnClick", CharacterSelectButton_OnClick);
	button:SetScript("OnDoubleClick", CharacterSelectButton_OnDoubleClick);
	button:SetScript("OnDragStart", CharacterSelectButton_OnDragStart);
	button:SetScript("OnDragStop", CharacterSelectButton_OnDragStop);
	-- Functions here copied from CharacterSelect.xml
	button:SetScript("OnMouseDown", function(self)
		CharacterSelect.pressDownButton = self;
		CharacterSelect.pressDownTime = 0;
	end);
	button.upButton:SetScript("OnClick", function(self)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
		local index = self:GetParent().index;
		MoveCharacter(index, index - 1);
	end);
	button.downButton:SetScript("OnClick", function(self)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
		local index = self:GetParent().index;
		MoveCharacter(index, index + 1);
	end);
	button:SetScript("OnEnter", function(self)
		if ( (self.isVeteranLocked or self.isWowTokenModeLocked) and CharSelectAccountUpgradeButton:IsEnabled()) then
			local text = CHARSELECT_CHAR_LIMITED_TOOLTIP;
			if (self.isWowTokenModeLocked) then
				text = CHARSELECT_CHAR_SUB_LIMITED_TOOLTIP;
			end
			GlueTooltip:SetText(text, nil, nil, nil, nil, true);
			GlueTooltip:Show();
			GlueTooltip:SetOwner(self, "ANCHOR_LEFT", -16, -5);
			CharSelectAccountUpgradeButtonPointerFrame:Show();
			CharSelectAccountUpgradeButtonGlow:Show();
		end
	end);
	button:SetScript("OnLeave", function(self)
		if ( self.upButton:IsShown() and not (self.upButton:IsMouseOver() or self.downButton:IsMouseOver()) ) then
			self.upButton:Hide();
			self.downButton:Hide();
		end
		CharSelectAccountUpgradeButtonPointerFrame:Hide();
		CharSelectAccountUpgradeButtonGlow:Hide();
		GlueTooltip:Hide();
	end);
	button:SetScript("OnMouseUp", CharacterSelectButton_OnDragStop);
end

local function disableScroll(scrollBar)
	scrollBar.ScrollUpButton:SetEnabled(false);
	scrollBar.ScrollDownButton:SetEnabled(false);
	scrollBar:GetParent():EnableMouseWheel(false);
end

local function enableScroll(scrollBar)
	scrollBar.ScrollUpButton:SetEnabled(true);
	scrollBar.ScrollDownButton:SetEnabled(true);
	scrollBar:GetParent():EnableMouseWheel(true);
end

local function replaceAllScripts()
	for i = 1, math.min(GetNumCharacters(), MAX_CHARACTERS_DISPLAYED) do
		local button = _G["CharSelectCharacterButton"..i];
		replaceScripts(button);
		button.upButton:Hide();
		button.downButton:Hide();
	end
end

function CharacterUpgrade_IsCreatedCharacterUpgrade()
	return C_CharacterCreation.GetCharacterCreateType() == Enum.CharacterCreateType.Boost;
end

function CharacterUpgrade_IsCreatedCharacterTrialBoost()
	return C_CharacterCreation.GetCharacterCreateType() == Enum.CharacterCreateType.TrialBoost;
end

function CharacterUpgrade_ResetBoostData()
	C_CharacterCreation.SetCharacterCreateType(Enum.CharacterCreateType.Normal);
	CHARACTER_UPGRADE_CREATE_CHARACTER_DATA = nil;
end

local function IsUsingValidProductForTrialBoost(flowData)
	local boostType = flowData.boostType;
	local requiredBoost = C_CharacterServices.GetActiveClassTrialBoostType();
	return boostType ~= nil and boostType == requiredBoost;
end

local function IsUsingValidProductForCreateNewCharacterBoost()
	-- To prevent player confusion, when trial boost create is shown, do not show the normal boost create character button
	-- As different products are added this may need to be updated to reflect specific cases, but for now it's
	-- sufficient to make trial/normal create mutually exclusive.
	return not C_CharacterServices.IsTrialBoostEnabled() or not IsUsingValidProductForTrialBoost(CharacterUpgradeFlow.data);
end

local function IsBoostFlowValidForCharacter(flowData, classID, level, raceID, boostInProgress, isTrialBoost, revokedCharacterUpgrade, vasServiceInProgress, isExpansionTrialCharacter, hasWowToken, usedMaxLevelBoost)
	if (boostInProgress or vasServiceInProgress or hasWowToken) then
		return false;
	end

	if not C_CharacterServices.IsBoostEnabled() then
		return false;
	end

	if C_CharacterServices.DoesBoostTypeRestrictClass(flowData.boostType, classID) then
		return false;
	end

	if C_CharacterServices.DoesBoostTypeRestrictRace(flowData.boostType, raceID) then
		return false;
	end

	if level == flowData.level and not revokedCharacterUpgrade then
		local allowMaxLevelBoost = bit.band(flowData.flags, CHARACTERSERVICEINFO_FLAGS_ALLOW_MAX_LEVEL_BOOST) == CHARACTERSERVICEINFO_FLAGS_ALLOW_MAX_LEVEL_BOOST;
		if (not allowMaxLevelBoost) or usedMaxLevelBoost then
			return false;
		end
	end

	if isExpansionTrialCharacter and CanUpgradeExpansion() then
		return false;
	elseif isTrialBoost then
		if level >= flowData.level and not IsUsingValidProductForTrialBoost(flowData) then
			return false;
		end
	elseif revokedCharacterUpgrade then
		if level > flowData.level then
			return false;
		end
	else
		if level > flowData.level then
			return false;
		end
	end

	return true;
end

local function CanBoostCharacter(classID, level, raceID, boostInProgress, isTrialBoost, revokedCharacterUpgrade, vasServiceInProgress, isExpansionTrialCharacter, hasWowToken, usedMaxLevelBoost)
	return IsBoostFlowValidForCharacter(CharacterUpgradeFlow.data, classID, level, raceID, boostInProgress, isTrialBoost, revokedCharacterUpgrade, vasServiceInProgress, isExpansionTrialCharacter, hasWowToken, usedMaxLevelBoost);
end

local function IsCharacterEligibleForVeteranBonus(level, isTrialBoost, revokedCharacterUpgrade)
	return false;
end

local function SetCharacterButtonEnabled(button, enabled)
	if enabled then
		button.buttonText.name:SetTextColor(1, 0.82, 0);
		button.buttonText.Info:SetTextColor(1, 1, 1);
		button.buttonText.Location:SetTextColor(0.5, 0.5, 0.5);
	else
		button.buttonText.name:SetTextColor(0.25, 0.25, 0.25);
		button.buttonText.Info:SetTextColor(0.25, 0.25, 0.25);
		button.buttonText.Location:SetTextColor(0.25, 0.25, 0.25);
	end

	button:SetEnabled(enabled);
end

local function formatDescription(description, gender)
	if (not strfind(description, "%$")) then
		return description;
	end

	-- This is a very simple parser that will only handle $G/$g tokens
	return gsub(description, "$[Gg]([^:]+):([^;]+);", "%"..gender);
end

function IsExpansionTrialCharacter(characterGUID)
	local isExpansionTrialCharacter = select(28, GetCharacterInfoByGUID(characterGUID));
	return isExpansionTrialCharacter;
end

function GetAvailableBoostTypesForCharacterByGUID(characterGUID)
	local availableBoosts = {};
	local upgradeDistributions = C_SharedCharacterServices.GetUpgradeDistributions();
	if upgradeDistributions then
		local _, _, _, _, _, classID, level, _, _, _, _, _, _, _, playerguid, _, _, _, boostInProgress, _, _, isTrialBoost, _, revokedCharacterUpgrade, vasServiceInProgress, _, _, isExpansionTrialCharacter, _, _, _, raceID, _, hasWowToken, _, usedMaxLevelBoost = GetCharacterInfoByGUID(characterGUID);
		for boostType, data in pairs(upgradeDistributions) do
			if IsBoostFlowValidForCharacter(C_CharacterServices.GetCharacterServiceDisplayData(boostType), classID, level, raceID, boostInProgress, isTrialBoost, revokedCharacterUpgrade, vasServiceInProgress, isExpansionTrialCharacter, hasWowToken, usedMaxLevelBoost) then
				availableBoosts[#availableBoosts + 1] = boostType;
			end
		end
	end

	return availableBoosts;
end

function CharacterUpgradeCharacterSelectBlock:SetCharacterSelectErrorFrameShown(showError)
	local errorFrame = CharacterUpgradeMaxCharactersFrame;
	if showError then
		self.frame:Hide(); -- Hide the flow manager

		if not errorFrame.initialized then
			errorFrame:SetPoint("TOP", CharacterServicesMaster, "TOP", -30, 0);
			errorFrame:SetFrameLevel(CharacterServicesMaster:GetFrameLevel() + 2);
			errorFrame:SetParent(CharacterServicesMaster);
			errorFrame.initialized = true;
		end
	end

	errorFrame:SetShown(showError);
end

function CharacterUpgradeCharacterSelectBlock:GetStepOptionFrames()
	local optionFrames = self.frame.CharacterSelectBlockOptionFrames;
	local conjunctionFrames = self.frame.CharacterSelectBlockConjunctionFrames;

	if not optionFrames then
		self.OPTION_INDEX_STEP_LABEL = 1;
		self.OPTION_INDEX_CREATE_NEW_CHARACTER = 2;
		self.OPTION_INDEX_CREATE_TRIAL_CHARACTER = 3;
		self.OPTION_INDEX_CREATE_TRIAL_CHARACTER_HINT = 4;

		-- Put all options (select char, create new, create trial) into this container
		-- The anchor data is used when the given frame is the first one being anchored to the block
		-- When anchoring subsequent frames they just use offsets from the "or labels" and always
		-- anchor topleft -> bottomleft of the previous frame
		optionFrames = {
			[self.OPTION_INDEX_STEP_LABEL] = {
				frame = self.frame.StepActiveLabel,
				point = "LEFT", relativeFrame = self.frame.StepNumber, relativePoint ="RIGHT", offsetX = 9, offsetY = 3,
				offsetXConjunction = 0, offsetYConjunction = -8,
			},

			[self.OPTION_INDEX_CREATE_NEW_CHARACTER] = {
				frame = self.frame.ControlsFrame.CreateCharacterButton,
				needsConjunction = true,
				point = "LEFT", relativeFrame = self.frame.StepNumber, relativePoint ="RIGHT", offsetX = 9, offsetY = 3,
				offsetXConjunction = 10, offsetYConjunction = -5,
			},

			[self.OPTION_INDEX_CREATE_TRIAL_CHARACTER] = {
				frame = self.frame.ControlsFrame.CreateCharacterClassTrialButton,
				needsConjunction = true,
				point = "TOPLEFT", relativeFrame = self.frame.StepNumber, relativePoint ="TOPRIGHT", offsetX = 10, offsetY = 0,
				offsetXConjunction = 10, offsetYConjunction = -5,
			},

			[self.OPTION_INDEX_CREATE_TRIAL_CHARACTER_HINT] = {
				frame = self.frame.ControlsFrame.ClassTrialButtonHintText,
				offsetXConjunction = 13, offsetYConjunction = -5,
			},
		};

		conjunctionFrames = {
			{ frame = self.frame.ControlsFrame.OrLabel, },
			{ frame = self.frame.ControlsFrame.OrLabel2, },
		};

		self.frame.CharacterSelectBlockOptionFrames = optionFrames;
		self.frame.CharacterSelectBlockConjunctionFrames = conjunctionFrames;
	end

	return optionFrames, conjunctionFrames;
end

function CharacterUpgradeCharacterSelectBlock:SetOptionUsed(optionIndex, used)
	local optionFrames = self:GetStepOptionFrames();
	optionFrames[optionIndex].used = used;
end

function CharacterUpgradeCharacterSelectBlock:ResetStepOptionFrames()
	local optionFrames, conjunctionFrames = self:GetStepOptionFrames();

	for i, optionData in ipairs(optionFrames) do
		optionData.frame:Hide();
		optionData.frame:ClearAllPoints();
	end

	for i, conjunctionData in ipairs(conjunctionFrames) do
		conjunctionData.frame:Hide();
		conjunctionData.frame:ClearAllPoints();
	end
end

function CharacterUpgradeCharacterSelectBlock:LayoutOptionFrames()
	local optionFrames, conjunctionFrames = self:GetStepOptionFrames();
	local previousFrameData;
	local optionCount = 0;

	for i, optionFrameData in ipairs(optionFrames) do
		if optionFrameData.used then
			if optionCount > 0 and optionFrameData.needsConjunction then
				local conjunctionFrameData = conjunctionFrames[optionCount];
				local conjunctionFrame = conjunctionFrameData.frame;
				conjunctionFrame:Show();
				conjunctionFrame:SetPoint("TOPLEFT", previousFrameData.frame, "BOTTOMLEFT", -previousFrameData.offsetXConjunction, previousFrameData.offsetYConjunction);
				previousFrameData = conjunctionFrameData;
			end

			optionFrameData.frame:Show();

			if optionCount == 0 then
				optionFrameData.frame:SetPoint(optionFrameData.point, optionFrameData.relativeFrame, optionFrameData.relativePoint, optionFrameData.offsetX, optionFrameData.offsetY);
			else
				optionFrameData.frame:SetPoint("TOPLEFT", previousFrameData.frame, "BOTTOMLEFT", optionFrameData.offsetXConjunction, optionFrameData.offsetYConjunction);
			end

			previousFrameData = optionFrameData;
			optionCount = optionCount + 1;
		end
	end
end

function CharacterUpgradeCharacterSelectBlock:SaveResultInfo(characterSelectButton, playerguid)
	self.index = characterSelectButton:GetID();
	self.charid = GetCharIDFromIndex(self.index + CHARACTER_LIST_OFFSET);
	self.playerguid = playerguid;
end

function CharacterUpgradeCharacterSelectBlock:ClearResultInfo()
	self.index = nil;
	self.charid = nil;
	self.playerguid = nil;
end

function CharacterUpgradeCharacterSelectBlock:OnRewind()
	self:ClearResultInfo();
end

function CharacterUpgradeCharacterSelectBlock:Initialize(results)
	for i = 1, 3 do
		if (self.frame.BonusResults[i]) then
			self.frame.BonusResults[i]:Hide();
		end
	end
	self.seenPopup = false;
	self.frame.NoBonusResult:Hide();
	enableScroll(CharacterSelectCharacterFrame.scrollBar);

	self:ClearResultInfo();
	self.lastSelectedIndex = CharacterSelect.selectedIndex;

	local numCharacters = GetNumCharacters();
	local numDisplayedCharacters = math.min(numCharacters, MAX_CHARACTERS_DISPLAYED);

	if (CharacterUpgrade_IsCreatedCharacterUpgrade()) then
		CharacterSelect_UpdateButtonState();
		CHARACTER_LIST_OFFSET = max(numCharacters - MAX_CHARACTERS_DISPLAYED, 0);

		if (self.createNum < numCharacters) then
			CharacterSelectCharacterFrame.scrollBar.blockUpdates = true;
			CharacterSelectCharacterFrame.scrollBar:SetValue(CHARACTER_LIST_OFFSET);
			CharacterSelectCharacterFrame.scrollBar.blockUpdates = nil;

			UpdateCharacterSelection(CharacterSelect);

			self.index = CharacterSelect.selectedIndex - CHARACTER_LIST_OFFSET;
			self.charid = GetCharIDFromIndex(CharacterSelect.selectedIndex);
			self.playerguid = select(15, GetCharacterInfo(self.charid));

			local button = _G["CharSelectCharacterButton"..numDisplayedCharacters];
			replaceScripts(button);

			CharacterServicesMaster_Update();

			return;
		end
	end

	CharacterSelect_SaveCharacterOrder();
	-- Set up the GlowBox around the show characters
	self.frame.ControlsFrame.GlowBox:SetHeight(58 * numDisplayedCharacters);
	if (CharacterSelectCharacterFrame.scrollBar:IsShown()) then
		self.frame.ControlsFrame.GlowBox:SetPoint("TOP", CharacterSelectCharacterFrame, -8, -60);
		self.frame.ControlsFrame.GlowBox:SetWidth(238);
	else
		self.frame.ControlsFrame.GlowBox:SetPoint("TOP", CharacterSelectCharacterFrame, 2, -60);
		self.frame.ControlsFrame.GlowBox:SetWidth(244);
	end
	for i = 1, MAX_CHARACTERS_DISPLAYED do
		if (not self.frame.ControlsFrame.Arrows[i]) then
			self.frame.ControlsFrame.Arrows[i] = CreateFrame("Frame", nil, self.frame.ControlsFrame, "CharacterServicesArrowTemplate");
		end
		if (not self.frame.ControlsFrame.BonusIcons[i]) then
			self.frame.ControlsFrame.BonusIcons[i] = CreateFrame("Frame", nil, self.frame.ControlsFrame, "CharacterServicesBonusIconTemplate");
		end
		local arrow = self.frame.ControlsFrame.Arrows[i];
		local bonusIcon = self.frame.ControlsFrame.BonusIcons[i];
		arrow:SetPoint("RIGHT", _G["CharSelectCharacterButton"..i], "LEFT", -8, 8);
		bonusIcon:SetPoint("LEFT", _G["CharSelectCharacterButton"..i.."ButtonTextName"], "RIGHT", -1, 0);
		arrow:Hide();
		bonusIcon:Hide();
	end

	CharacterSelect.selectedIndex = -1;
	UpdateCharacterSelection(CharacterSelect);

	local numEligible = 0;
	self.hasVeteran = false;
	replaceAllScripts();

	for i = 1, numDisplayedCharacters do
		local button = _G["CharSelectCharacterButton"..i];
		_G["CharSelectPaidService"..i]:Hide();
		local _, _, _, _, _, classID, level, _, _, _, _, _, _, _, playerguid, _, _, _, boostInProgress, _, _, isTrialBoost, _, revokedCharacterUpgrade, vasServiceInProgress, _, _, isExpansionTrialCharacter, _, _, _, _, _, raceID, _, hasWowToken, _, maxLevelBoostUsed = GetCharacterInfo(GetCharIDFromIndex(i+CHARACTER_LIST_OFFSET));
		local canBoostCharacter = CanBoostCharacter(classID, level, raceID, boostInProgress, isTrialBoost, revokedCharacterUpgrade, vasServiceInProgress, isExpansionTrialCharacter, hasWowToken, maxLevelBoostUsed);

		SetCharacterButtonEnabled(button, canBoostCharacter);

		if (canBoostCharacter) then
			self.frame.ControlsFrame.Arrows[i]:Show();
			self.frame.ControlsFrame.BonusIcons[i]:SetShown(IsCharacterEligibleForVeteranBonus(level, isTrialBoost, revokedCharacterUpgrade));

			button:SetScript("OnClick", function(button)
				self:SaveResultInfo(button, playerguid);

				-- The user entered a normal boost flow and selected a trial boost character, at this point
				-- put the flow into the auto-select state.
				local trialBoostFlowGuid = isTrialBoost and playerguid or nil;
				CharacterUpgradeFlow:SetTrialBoostGuid(trialBoostFlowGuid);

				CharacterSelectButton_OnClick(button);
				CharacterServicesMaster_Update();
			end)

			-- Determine if this should auto-advance and cache off relevant information
			-- NOTE: CharacterUpgradeCharacterSelectBlock always uses auto-advance, there's no "next"
			-- button, so once a character is selected it has to advance automatically.
			if CharacterUpgradeFlow:GetAutoSelectGuid() == playerguid then
				self:SaveResultInfo(button, playerguid);
			end
		end
	end

	for i = 1, GetNumCharacters() do
		local _, _, _, _, _, classID, level, _, _, _, _, _, _, _, playerguid, _, _, _, boostInProgress, _, _, isTrialBoost, _, revokedCharacterUpgrade, vasServiceInProgress, _, _, isExpansionTrialCharacter, _, _, _, _, _, raceID, _, hasWowToken, _, maxLevelBoostUsed = GetCharacterInfo(GetCharIDFromIndex(i));
		if CanBoostCharacter(classID, level, raceID, boostInProgress, isTrialBoost, revokedCharacterUpgrade, vasServiceInProgress, isExpansionTrialCharacter, hasWowToken, maxLevelBoostUsed) then
			if IsCharacterEligibleForVeteranBonus(level, isTrialBoost, revokedCharacterUpgrade) then
				self.hasVeteran = true;
			end
			numEligible = numEligible + 1;
		end
	end

	self.frame.ControlsFrame.BonusLabel:SetHeight(self.frame.ControlsFrame.BonusLabel.BonusText:GetHeight());
	self.frame.ControlsFrame.BonusLabel:SetPoint("BOTTOM", CharSelectServicesFlowFrame, "BOTTOM", 10, 60);
	self.frame.ControlsFrame.BonusLabel:SetShown(self.hasVeteran);

	-- Setup the step option frames
	self:ResetStepOptionFrames();

	local hasEligibleBoostCharacter = (numEligible > 0);
	local canCreateCharacter = CanCreateCharacter();
	local canShowCreateNewCharacterButton = canCreateCharacter and IsUsingValidProductForCreateNewCharacterBoost();
	local canCreateTrialBoostCharacter = canCreateCharacter and (C_CharacterServices.IsTrialBoostEnabled() and IsUsingValidProductForTrialBoost(CharacterUpgradeFlow.data));

	self:SetOptionUsed(self.OPTION_INDEX_STEP_LABEL, hasEligibleBoostCharacter);
	self:SetOptionUsed(self.OPTION_INDEX_CREATE_NEW_CHARACTER, canShowCreateNewCharacterButton);
	self:SetOptionUsed(self.OPTION_INDEX_CREATE_TRIAL_CHARACTER, canCreateTrialBoostCharacter);
	self:SetOptionUsed(self.OPTION_INDEX_CREATE_TRIAL_CHARACTER_HINT, canCreateTrialBoostCharacter and not (hasEligibleBoostCharacter or canShowCreateNewCharacterButton));

	self:LayoutOptionFrames();

	-- Glowbox hides without eligible characters
	self.frame.ControlsFrame.GlowBox:SetShown(hasEligibleBoostCharacter);

	local canCreateBoostableCharacter = canCreateCharacter and (canShowCreateNewCharacterButton or canCreateTrialBoostCharacter);
	local showBoostError = not (canCreateBoostableCharacter or hasEligibleBoostCharacter);
	self:SetCharacterSelectErrorFrameShown(showBoostError);
end

function CharacterUpgradeCharacterSelectBlock:ShouldShowPopup()
	local _, _, raceFilename = GetCharacterInfo(self.charid);
	local raceData = C_CharacterCreation.GetRaceDataByID(C_CharacterCreation.GetRaceIDFromName(raceFilename));
	local seenPopupBefore = self.seenPopup;
	self.seenPopup = true;
	local isTrialBoost = select(22, GetCharacterInfo(self.charid));
	return not isTrialBoost and raceData.isAlliedRace and not raceData.hasHeritageArmor and not seenPopupBefore;
end

function CharacterUpgradeCharacterSelectBlock:GetPopupText()
	local _, _, raceFilename, _, _, _, _, _, _, _, _, _, _, _, _, _, _, gender = GetCharacterInfo(self.charid);
	local raceData = C_CharacterCreation.GetRaceDataByID(C_CharacterCreation.GetRaceIDFromName(raceFilename));

	if GetCurrentRegionName() == "CN" then
		return formatDescription(BOOST_ALLIED_RACE_HERITAGE_ARMOR_WARNING_CN:format(raceData.name), gender+1);
	else
		return formatDescription(BOOST_ALLIED_RACE_HERITAGE_ARMOR_WARNING:format(raceData.name), gender+1);
	end
end

function CharacterUpgradeCharacterSelectBlock:IsFinished()
	return self.charid ~= nil;
end

function CharacterUpgradeCharacterSelectBlock:GetResult()
	return { charid = self.charid; playerguid = self.playerguid; }
end

function CharacterUpgradeCharacterSelectBlock:FormatResult()
	local name, _, _, class, classFileName, _, level, _, _, _, _, _, _, _, _, prof1, prof2, _, _, _, _, isTrialBoost, _, revokedCharacterUpgrade = GetCharacterInfo(self.charid);
	if (IsCharacterEligibleForVeteranBonus(level, isTrialBoost, revokedCharacterUpgrade)) then
		local defaults = defaultProfessions[classDefaultProfessionMap[classFileName]];
		if (prof1 == 0 and prof2 == 0) then
			prof1 = defaults[1];
			prof2 = defaults[2];
		elseif (prof1 == 0) then
			if (prof2 == defaults[1]) then
				prof1 = defaults[2];
			else
				prof1 = defaults[1];
			end
		elseif (prof2 == 0) then
			if (prof1 == defaults[1]) then
				prof2 = defaults[2];
			else
				prof2 = defaults[1];
			end
		end
		local bonuses = {
			[1] = professionsMap[prof1],
			[2] = professionsMap[prof2],
			[3] = CHARACTER_PROFESSION_FIRST_AID
		};
		for i = 1,3 do
			if (not self.frame.BonusResults[i]) then
				local frame = CreateFrame("Frame", nil, self.frame, "CharacterServicesBonusResultTemplate");
				self.frame.BonusResults[i] = frame;
			end
			local result = self.frame.BonusResults[i];
			if ( i == 1 ) then
				result:SetPoint("TOPLEFT", self.frame.ResultsLabel, "BOTTOMLEFT", 0, -2);
			else
				result:SetPoint("TOPLEFT", self.frame.BonusResults[i-1], "BOTTOMLEFT", 0, -2);
			end
			result.Label:SetText(CHARACTER_UPGRADE_PROFESSION_BOOST_RESULT_FORMAT:format(bonuses[i], CharacterUpgradeFlow.data.professionLevel));
			result:Show();
		end
	elseif (self.hasVeteran) then
		self.frame.NoBonusResult:Show();
	end
	return SELECT_CHARACTER_RESULTS_FORMAT:format(RAID_CLASS_COLORS[classFileName].colorStr, name, level, class);
end

local g_filteringByBoostsOnly = nil;
function CharacterUpgradeCharacterSelectBlock_IsFilteringByBoostable()
	return g_filteringByBoostsOnly;
end

function CharacterUpgradeCharacterSelectBlock_SetFilteringByBoostable(boostsOnly)
	g_filteringByBoostsOnly = boostsOnly;
end

function CharacterUpgradeCharacterSelectBlock:OnHide()
	enableScroll(CharacterSelectCharacterFrame.scrollBar);

	local num = math.min(GetNumCharacters(), MAX_CHARACTERS_DISPLAYED);

	for i = 1, num do
		local button = _G["CharSelectCharacterButton"..i];
		resetScripts(button);
		SetCharacterButtonEnabled(button, true);

		if (button.padlock) then
			button.padlock:Show();
		end
	end

	UpdateCharacterList(true);
	local index = self.lastSelectedIndex;
	if (self:IsFinished()) then
		index = self.index;
	end
	if (index <= 0 or index > MAX_CHARACTERS_DISPLAYED) then return end;
	CharacterSelect.selectedIndex = index;
	local button = _G["CharSelectCharacterButton"..index];
	CharacterSelectButton_OnClick(button);
end

function CharacterUpgradeCharacterSelectBlock:OnAdvance()
	disableScroll(CharacterSelectCharacterFrame.scrollBar);

	local selectedButtonIndex = math.min(self.index, MAX_CHARACTERS_DISPLAYED);
	local numDisplayedCharacters = math.min(GetNumCharacters(), MAX_CHARACTERS_DISPLAYED);

	for buttonIndex = 1, numDisplayedCharacters do
		_G["CharSelectPaidService"..buttonIndex]:Hide();
		if (buttonIndex ~= selectedButtonIndex) then
			local button = _G["CharSelectCharacterButton"..buttonIndex];
			SetCharacterButtonEnabled(button, false);
		end
	end
end

function CharacterUpgradeSelectCharacterFrame_OnLoad(self)
	local controls = self.ControlsFrame;
	local buttonWidth = max(controls.CreateCharacterButton:GetTextWidth(), controls.CreateCharacterClassTrialButton:GetTextWidth()) + 50;
	controls.CreateCharacterButton:SetWidth(buttonWidth);
	controls.CreateCharacterClassTrialButton:SetWidth(buttonWidth);

	controls.OrLabel2:SetPoint("TOPLEFT", controls.CreateCharacterButton, "BOTTOMLEFT", 0, -5);
end

function CharacterUpgrade_SetupFlowForNewCharacter(characterType)
	if characterType == Enum.CharacterCreateType.Boost then
		CharacterUpgradeCharacterSelectBlock.createNum = GetNumCharacters();

		if CharacterServicesMaster.flow then
			CHARACTER_UPGRADE_CREATE_CHARACTER_DATA = CharacterServicesMaster.flow.data;
		end
	end
end

function CharacterUpgrade_BeginNewCharacterCreation(characterType)
	CharacterUpgrade_SetupFlowForNewCharacter(characterType);
	CharacterSelect_CreateNewCharacter(characterType, false);
end

function CharacterUpgradeCreateCharacter_OnClick(self)
	CharacterUpgrade_BeginNewCharacterCreation(Enum.CharacterCreateType.Boost);
end

function CharacterUpgradeClassTrial_OnClick(self)
	CharSelectServicesFlowFrame:Hide();
	CharacterUpgrade_BeginNewCharacterCreation(Enum.CharacterCreateType.TrialBoost);
end

function CharacterUpgradeEndStep:Initialize(results)
	CharacterServicesMaster_Update();
end

function CharacterUpgradeEndStep:IsFinished()
	return true;
end

function CharacterUpgradeEndStep:GetResult()
	return {};
end

function CharacterUpgradeEndStep:OnRewind()
	if (CharacterUpgradeSecondChanceWarningFrame:IsShown()) then
		CharacterUpgradeSecondChanceWarningFrame:Hide();
	end
end

function CharacterUpgradeFactionSelectBlock:Initialize(results, wasFromRewind)
	local factionName = C_CharacterServices.GetFactionGroupByIndex(results.charid)

	if FACTION_IDS[factionName] then
		self.faction = FACTION_IDS[factionName];
	else
		self.faction = -1;
	end

	local function SelectFaction(factionID)
		self.faction = factionID;
		CharacterServicesMaster_Update();
	end

	local hordeText = SELECT_FACTION_RESULTS_FORMAT:format(factionColors[0], FACTION_HORDE);
	local allianceText = SELECT_FACTION_RESULTS_FORMAT:format(factionColors[1], FACTION_ALLIANCE);

	self.frame.ControlsFrame.Dropdown:SetupMenu(function(dropdown, rootDescription)
		rootDescription:CreateRadio(hordeText, function() return false; end, SelectFaction, 0);
		rootDescription:CreateRadio(allianceText, function() return false; end, SelectFaction, 1);
	end);

	CharacterServicesMaster_Update();
end

function CharacterUpgradeFactionSelectBlock:IsFinished(wasFromRewind)
	return self.faction and self.faction >= 0;
end

function CharacterUpgradeFactionSelectBlock:GetResult()
	return { faction = self.faction };
end

function CharacterUpgradeFactionSelectBlock:SkipIf(results)
	local factionName = C_CharacterServices.GetFactionGroupByIndex(results.charid)
	return FACTION_IDS[factionName] ~= nil;
end


function CharacterUpgradeFactionSelectBlock:FormatResult()
	local factionName = factionLabels[self.faction] or "";
	local color = factionColors[self.faction] or 0

	return SELECT_FACTION_RESULTS_FORMAT:format(color, factionName);
end
