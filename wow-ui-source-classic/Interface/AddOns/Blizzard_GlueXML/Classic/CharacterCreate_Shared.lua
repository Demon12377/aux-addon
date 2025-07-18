CHARACTER_FACING_INCREMENT = 2;
NUM_CHAR_CUSTOMIZATIONS = 5;
MIN_CHAR_NAME_LENGTH = 2;
PANDAREN_RACE_ID = 13;

FACTION_BACKDROP_COLOR_TABLE = {
	Alliance = {
		color = GLUE_ALLIANCE_COLOR,
		borderColor = GLUE_ALLIANCE_BORDER_COLOR,
	},
	Horde = {
		color = GLUE_HORDE_COLOR,
		borderColor = GLUE_HORDE_BORDER_COLOR,
	},
	Player = {
		color = GLUE_NEUTRAL_COLOR,
		borderColor = GLUE_NEUTRAL_BORDER_COLOR,
	},
};

function CharacterCreateEnumerateRaces()
	local races = C_CharacterCreation.GetAvailableRaces();
	CharacterCreate.numRaces = #races;
	if ( CharacterCreate.numRaces > MAX_RACES ) then
		message("Too many races!  Update MAX_RACES");
		return;
	end

	local isBoostedCharacter = CharacterUpgrade_IsCreatedCharacterUpgrade() or CharacterUpgrade_IsCreatedCharacterTrialBoost();
	local coords;
	local button;
	local gender;
	if ( C_CharacterCreation.GetSelectedSex() == Enum.UnitSex.Male ) then
		gender = "MALE";
	else
		gender = "FEMALE";
	end
	for index, raceData in pairs(races) do
		coords = RACE_ICON_TCOORDS[strupper(raceData.fileName.."_"..gender)];

		local normalTexture = _G["CharacterCreateRaceButton"..index].normalTexture;
		local pushedTexture = _G["CharacterCreateRaceButton"..index].pushedTexture;

		normalTexture:SetTexCoord(coords[1], coords[2], coords[3], coords[4]);

		if pushedTexture then -- Not all versions have the pushed texture
			pushedTexture:SetTexCoord(coords[1], coords[2], coords[3], coords[4]);
		end

		button = _G["CharacterCreateRaceButton"..index];
		button:Show();
		button.tooltip = nil;

		local disable = true;
		if CharacterCreateFrame.paidServiceType == PAID_FACTION_CHANGE or CharacterCreateFrame.vasType == Enum.ValueAddedServiceType.PaidFactionChange then
			local _, currentFaction = C_PaidServices.GetCurrentFaction();
			if CharacterCreateFrame.vasType == Enum.ValueAddedServiceType.PaidFactionChange then
				currentFaction = select(29, GetCharacterInfoByGUID(CharacterCreateFrame.vasInfo.selectedCharacterGUID));
			end
			local currentClass = C_PaidServices.GetCurrentClassID();
			if (currentFaction ~= raceData.factionInternalName and C_CharacterCreation.IsRaceClassValid(raceData.raceID, currentClass)) then
				disable = false;
			end
		elseif CharacterCreateFrame.paidServiceType == PAID_RACE_CHANGE or CharacterCreateFrame.vasType == Enum.ValueAddedServiceType.PaidRaceChange then
			local _, currentFaction = C_PaidServices.GetCurrentFaction();
			if CharacterCreateFrame.vasType == Enum.ValueAddedServiceType.PaidRaceChange then
				currentFaction = select(29, GetCharacterInfoByGUID(CharacterCreateFrame.vasInfo.selectedCharacterGUID));
			end
			local currentRace = C_PaidServices.GetCurrentRaceID();
			local currentClass = C_PaidServices.GetCurrentClassID();
			local factionCheck = currentFaction == raceData.factionInternalName or raceData.isNeutralRace;
			if (factionCheck and currentRace ~= raceData.raceID and C_CharacterCreation.IsRaceClassValid(raceData.raceID, currentClass)) then
				disable = false;
			end
		elseif isBoostedCharacter and CharacterUpgradeFlow and CharacterUpgradeFlow.data and CharacterUpgradeFlow.data.boostType and C_CharacterServices.DoesBoostTypeRestrictRace(CharacterUpgradeFlow.data.boostType, raceData.raceID) then
			disable = true;
			button.tooltip = CHAR_CREATE_NO_BOOST;
		elseif not raceData.enabled then
			disable = true;
			button.tooltip = CHAR_CREATE_FACTION_BALANCE;
		else
			disable = false;
		end

		if disable then
			button:Disable();
			local texture = button:GetNormalTexture();
			if ( texture ) then
				texture:SetDesaturated(true);
			end
		else
			button:Enable();
			local texture = button:GetNormalTexture();
			if ( texture ) then
				texture:SetDesaturated(false);
			end
		end
		button.tooltip = raceData.name;

		button.raceID = raceData.raceID;
	end
	for i=#races + 1, MAX_RACES, 1 do
		_G["CharacterCreateRaceButton"..i]:Hide();
	end
end


function CharacterCreateEnumerateClasses()
	local classes = C_CharacterCreation.GetAvailableClasses();

	local numDisplayClasses = 0;
	local displayClasses = {};
	for index, classData in pairs(classes) do
		if (SHOW_UNAVAILABLE_CLASSES or classData.enabled) then
			numDisplayClasses = numDisplayClasses + 1;
			displayClasses[#displayClasses+1] = index;
		end
	end
	CharacterCreate.numClasses = numDisplayClasses;
	
	if ( CharacterCreate.numClasses > MAX_CLASSES_PER_RACE ) then
		message("Too many classes!  Update MAX_CLASSES_PER_RACE");
		return;
	end

	local isBoostedCharacter = CharacterUpgrade_IsCreatedCharacterUpgrade() or CharacterUpgrade_IsCreatedCharacterTrialBoost();
	local coords;
	local button;
	for index, classIndex in ipairs(displayClasses) do
		local classData = classes[classIndex];
		coords = CLASS_ICON_TCOORDS[strupper(classData.fileName)];
		_G["CharacterCreateClassButton"..index.."NormalTexture"]:SetTexCoord(coords[1], coords[2], coords[3], coords[4]);
		button = _G["CharacterCreateClassButton"..index];
		button:Show();

		local disable = true;
		if (CharacterCreateFrame:HasService()) then
			disable = C_PaidServices.GetCurrentClassID() ~= classData.classID;
		elseif (isBoostedCharacter and CharacterUpgradeFlow and CharacterUpgradeFlow.data and CharacterUpgradeFlow.data.boostType and C_CharacterServices.DoesBoostTypeRestrictClass(CharacterUpgradeFlow.data.boostType, classData.classID)) then
			disable = true;
			button.tooltip = CHAR_CREATE_NO_BOOST_CLASS;
		elseif (not classData.enabled) then 
			disable = true;
			button.tooltip = nil;
		else
			disable = false;
			button.tooltip = classData.name;
		end

		if (SHOW_UNAVAILABLE_CLASSES) then
			if (disable) then
				button:Disable();
				_G["CharacterCreateClassButton"..index.."DisableTexture"]:Show();
			else
				button:Enable();
				_G["CharacterCreateClassButton"..index.."DisableTexture"]:Hide();
			end
		end

		button.classID = classData.classID;
	end
	for i=CharacterCreate.numClasses+1, MAX_CLASSES_PER_RACE, 1 do
		_G["CharacterCreateClassButton"..i]:Hide();
	end
end

CharacterCreateMixin = {}

function CharacterCreateMixin:OnLoad()
	self:RegisterEvent("RANDOM_CHARACTER_NAME_RESULT");
	self:RegisterEvent("UPDATE_EXPANSION_LEVEL");
	self:RegisterEvent("CHARACTER_CREATION_RESULT");
	self:RegisterEvent("CUSTOMIZE_CHARACTER_STARTED");
	self:RegisterEvent("CUSTOMIZE_CHARACTER_RESULT");
	self:RegisterEvent("RACE_FACTION_CHANGE_STARTED");
	self:RegisterEvent("RACE_FACTION_CHANGE_RESULT");
	self:RegisterEvent("STORE_VAS_PURCHASE_ERROR");
	self:RegisterEvent("ASSIGN_VAS_RESPONSE");

	self.RotationConstant = 0.6;

	CharacterCreate:SetSequence(0);
	CharacterCreate:SetCamera(0);

	CharacterCreate.numRaces = 0;
	CharacterCreate.selectedRace = 0;
	CharacterCreate.numClasses = 0;
	CharacterCreate.selectedClass = 0;
	CharacterCreate.selectedGender = 0;

	C_CharacterCreation.SetCharCustomizeFrame("CharacterCreate");
	C_CharacterCreation.SetSelectedPreviewGearType(Enum.NewCharGear.Start);
	--CharCreateModel:SetLight(1, 0, 0, -0.707, -0.707, 0.7, 1.0, 1.0, 1.0, 0.8, 1.0, 1.0, 0.8);

	for i=1, NUM_CHAR_CUSTOMIZATIONS, 1 do
		_G["CharacterCustomizationButtonFrame"..i.."Text"]:SetText(_G["CHAR_CUSTOMIZATION"..i.."_DESC"]);
	end

	-- Color edit box backdrop
	local backdropColor = FACTION_BACKDROP_COLOR_TABLE["Alliance"];
	CharacterCreateNameEdit:SetBackdropBorderColor(backdropColor.borderColor:GetRGB());
	CharacterCreateNameEdit:SetBackdropColor(backdropColor.color:GetRGB());
end

function CharacterCreateMixin:OnShow()
	InitializeCharacterScreenData();
	SetInCharacterCreate(true);

	local existingCharacterID = self:GetExistingCharacterID();
	if existingCharacterID then
		C_CharacterCreation.CustomizeExistingCharacter(existingCharacterID);
		self.currentPaidServiceName = C_PaidServices.GetName();
		CharacterCreateNameEdit:SetText(self.currentPaidServiceName);
	else
		self.currentPaidServiceName = nil;
		--randomly selects a combination
		C_CharacterCreation.ResetCharCustomize();

		if C_Reincarnation.IsReincarnating() then
			local guid, charName = C_Reincarnation.GetReincarnatingCharacter();
			CharacterCreateNameEdit:SetText(charName);
			CharacterCreateNameEdit:Disable();
			CharacterCreateRandomName:Disable();
		else
			CharacterCreateNameEdit:SetText("");
		end

		if C_GameRules.IsHardcoreActive() then
			if (C_Reincarnation.IsReincarnating()) then
				CharCreateOkayButton:SetText(DEATH_REINCARNATE_CHARACTER);
			else
				CharCreateOkayButton:SetText(CHARACTER_CREATE_ACCEPT);
			end
		end
	end

	CharacterCreateEnumerateRaces();
	SetDefaultRace();

	CharacterCreateEnumerateClasses();
	SetDefaultClass();

	SetCharacterGender(C_CharacterCreation.GetSelectedSex());
	
	C_CharacterCreation.SetCharacterCreateFacing(-15);

	-- Set in locale files. We only support random names for English.
	if ( ALLOW_RANDOM_NAME_BUTTON and CharacterCreateNameEdit:IsShown() ) then
		CharacterCreateRandomName:Show();
	end

	if( IsKioskGlueEnabled() ) then
		local templateIndex = Kiosk.GetCharacterTemplateSetIndex();
		if (templateIndex) then
			C_CharacterCreation.SetCharacterTemplate(templateIndex);
		else
			C_CharacterCreation.ClearCharacterTemplate();
		end
	end
	CheckSelfFoundButton()
	if (CharacterReincarnatePopUpDialog) then
		CharacterReincarnatePopUpDialog:Hide();
	end
end

function CharacterCreateMixin:OnHide()
	if (self.state == "CUSTOMIZATION") then
		CharacterCreate_Back();
	end

	if CharacterCreatePreviewFrame then
		-- Character previews will need to be redone if coming back to character create. One reason is all the memory used for
		-- tracking the frames (on the c side) will get released if the user returns to the login screen.
		CharacterCreatePreviewFrame.rebuildPreviews = true;
	end

	SetInCharacterCreate(false);
	CharacterCreateFrame:ClearPaidServiceInfo();
	CharacterCreateFrame:ClearVASInfo();
end

function CharacterCreateMixin:OnEvent(event, ...)
	if ( event == "RANDOM_CHARACTER_NAME_RESULT" ) then
		local success, name = ...;
		if ( not success ) then
			-- Failed.  Generate a random name locally.
			CharacterCreateNameEdit:SetText(C_CharacterCreation.GenerateRandomName());
		else
			-- Succeeded.  Use what the server sent.
			CharacterCreateNameEdit:SetText(name);
		end
		CharacterCreateRandomName:Enable();
		PlaySound(SOUNDKIT.GS_CHARACTER_CREATION_LOOK);
	elseif ( event == "UPDATE_EXPANSION_LEVEL" ) then
		-- Expansion level changed while online, so enable buttons as needed
		if ( CharacterCreateFrame:IsShown() ) then
			CharacterCreateEnumerateRaces();
			CharacterCreateEnumerateClasses();
		end
	elseif ( event == "CHARACTER_CREATION_RESULT" ) then
		local success, errorCode, guid = ...;
		if ( success ) then
			CharacterSelect.selectGuid = guid;
			GlueParent_SetScreen("charselect");
		elseif (C_Reincarnation.IsReincarnating()) then
			GlueDialog_Show("OKAY", CHAR_CREATE_REINCARNATION_FAILED);
			-- Kick them back out to character select
		else	
			GlueDialog_Show("OKAY", _G[errorCode]);
		end
	elseif ( event == "CUSTOMIZE_CHARACTER_STARTED" ) then
		GlueDialog_Show("PAID_SERVICE_IN_PROGRESS", CHAR_CUSTOMIZE_IN_PROGRESS);
	elseif ( event == "CUSTOMIZE_CHARACTER_RESULT" ) then
		local success, err = ...;
		if ( success ) then
			GlueDialog_Hide("PAID_SERVICE_IN_PROGRESS");
			GlueParent_SetScreen("charselect");
		else
			GlueDialog_Show("OKAY", _G[err]);
		end
	elseif ( event == "RACE_FACTION_CHANGE_STARTED" ) then
		local changeType = ...;
		if ( changeType == "RACE" ) then
			GlueDialog_Show("PAID_SERVICE_IN_PROGRESS", RACE_CHANGE_IN_PROGRESS);
		elseif ( changeType == "FACTION" ) then
			GlueDialog_Show("PAID_SERVICE_IN_PROGRESS", FACTION_CHANGE_IN_PROGRESS);
		end
	elseif ( event == "RACE_FACTION_CHANGE_RESULT" ) then
		local success, err = ...;
		if ( success ) then
			GlueDialog_Hide("PAID_SERVICE_IN_PROGRESS");
			GlueParent_SetScreen("charselect");
		else
			GlueDialog_Show("OKAY", _G[err]);
		end
	elseif event == "STORE_VAS_PURCHASE_ERROR" then
		self:OnStoreVASPurchaseError();
	elseif event == "ASSIGN_VAS_RESPONSE" then
		local token, storeError, vasPurchaseResult = ...;
		self:OnAssignVASResponse(token, storeError, vasPurchaseResult);
	end
end

function CharacterCreateMixin:SetPaidServiceInfo(serviceType, characterID)
	self.paidServiceType = serviceType;
	self.paidServiceCharacterID = characterID;
	C_CharacterCreation.SetPaidService(serviceType ~= nil);
end

function CharacterCreateMixin:SetVASInfo(vasType, info)
	self.vasType = vasType;
	self.vasInfo = info;
	C_CharacterCreation.SetPaidService(vasType ~= nil);
end

function CharacterCreateMixin:ClearPaidServiceInfo()
	self.paidServiceType = nil;
	self.paidServiceCharacterID = nil;
	C_CharacterCreation.SetPaidService(false);
end

function CharacterCreateMixin:ClearVASInfo()
	self.vasType = nil;
	self.vasInfo = nil;	
	C_CharacterCreation.SetPaidService(false);
end

function CharacterCreateMixin:BeginVASTransaction()
	if self.vasType == Enum.ValueAddedServiceType.PaidFactionChange or self.vasType == Enum.ValueAddedServiceType.PaidRaceChange then
		local noIsValidateOnly = false;
		C_CharacterServices.AssignRaceOrFactionChangeDistribution(self.vasInfo.selectedCharacterGUID, CharacterCreateFrame:GetSelectedName(), noIsValidateOnly, self.vasType);
	end
end

function CharacterCreateMixin:IsVASErrorUserFixable(errorID)
	return errorID == Enum.VasError.NameNotAvailable or errorID == Enum.VasError.DuplicateCharacterName;
end

function CharacterCreateMixin:OnStoreVASPurchaseError()
	if self.vasType then
		local displayMsg = VASErrorData_GetCombinedMessage(self.vasInfo.selectedCharacterGUID);
		local errors = C_StoreSecure.GetVASErrors();
		local exitAfterError = false;
		for index, errorID in ipairs(errors) do
			if not self:IsVASErrorUserFixable(errorID) then
				exitAfterError = true;
				break;
			end
		end
		GlueDialog_Show("CHARACTER_CREATE_VAS_ERROR", displayMsg, exitAfterError);
	end
end

function CharacterCreateMixin:OnAssignVASResponse(token, storeError, vasPurchaseResult)
	if self.vasType then
		local purchaseComplete, errorMsg = IsVASAssignmentValid(storeError, vasPurchaseResult, self.vasInfo.selectedCharacterGUID);
		if purchaseComplete then
			CharacterSelect.selectGuid = self.vasInfo.selectedCharacterGUID;
			CharacterCreateFrame:Exit();
		else
			local exitAfterError = not self:IsVASErrorUserFixable(vasPurchaseResult);
			GlueDialog_Show("CHARACTER_CREATE_VAS_ERROR", errorMsg, exitAfterError);
		end
	end
end

function CharacterCreateMixin:HasService()
	return (self.paidServiceType or self.vasType) and true or false;
end

function CharacterCreateMixin:GetExistingCharacterID()
	if self.paidServiceType then
		return self.paidServiceCharacterID;
	elseif self.vasType then
		return self.vasInfo.characterIndex;
	end
	return nil;
end

function CharacterCreateMixin:OnMouseDown(button)
	if ( button == "LeftButton" ) then
		self.lastCursorPosX = GetCursorPosition();
	end
end

function CharacterCreateMixin:OnMouseUp(button)
	if ( button == "LeftButton" ) then
		self.lastCursorPosX = nil;
	end
end

function CharacterCreateMixin:OnUpdate(elapsed)
	if ( self.lastCursorPosX ) then
		local x = GetCursorPosition();
		local diff = (x - self.lastCursorPosX) * self.RotationConstant;
		self.lastCursorPosX = x;
		C_CharacterCreation.SetCharacterCreateFacing(C_CharacterCreation.GetCharacterCreateFacing() + diff);
		CharacterCreate_RotatePreviews();
	end
end

function CharacterCreateMixin:GetSelectedName()
	return CharacterCreateNameEdit:GetText();
end

function CharacterCreateMixin:Exit()
	CHARACTER_SELECT_BACK_FROM_CREATE = true;
	GlueParent_SetScreen("charselect");
end

function CharacterCreateMixin:OnMouseWheel(delta)
	if CharacterCreatePreviewFrame and CharacterCreatePreviewFrame:IsShown() then
		CharacterCreate_ChangeFeatureVariation(delta * -1);
	end
end

function CharacterCreate_OnChar()
end

function CharacterCreate_OnKeyDown(self, key)
	if ( key == "PRINTSCREEN" ) then
		Screenshot();
	elseif key == "ENTER" then
		CharacterCreate_Forward();
	elseif key == "ESCAPE" then
		CharacterCreate_Back();
	end
end

function CharacterCreate_UpdateModel(self)
	C_CharacterCreation.UpdateCustomizationScene();
end

function CharacterCreate_GetCurrentStateIndex()

	if not CHARACTER_CREATE_STATES then
		return 1;
	end

	if CharacterCreateFrame.state then
		for i=1, #CHARACTER_CREATE_STATES do
			if CharacterCreateFrame.state == CHARACTER_CREATE_STATES[i] then
				return i;
			end
		end
	end

	return 1;
end

function CharacterCreate_GetNumStates()
	if not CHARACTER_CREATE_STATES then
		return 1;
	end
	return #CHARACTER_CREATE_STATES;
end

function CharacterCreate_Back()

	local stateIndex = CharacterCreate_GetCurrentStateIndex();

	if stateIndex <= 1 then
		if( IsKioskGlueEnabled() ) then
			PlaySound(SOUNDKIT.GS_CHARACTER_CREATION_CANCEL);
			GlueParent_SetScreen("kioskmodesplash");
		else
			PlaySound(SOUNDKIT.GS_CHARACTER_CREATION_CANCEL);
			CHARACTER_SELECT_BACK_FROM_CREATE = true;
			GlueParent_SetScreen("charselect");
		end
		return;
	end

	CharacterCreateFrame.state = CHARACTER_CREATE_STATES[stateIndex - 1];

	if CharacterCreateFrame.state == "CLASSRACE" then
		PlaySound(SOUNDKIT.GS_CHARACTER_CREATION_CANCEL);
		CharacterCreateClassFrame:Show();
		CharacterCreateRaceFrame:Show();
		CharacterCreateMoreInfoButton:Show();
		CharacterCustomizationFrame:Hide();
		CharacterCreatePreviewFrame:Hide();
		CharCreateOkayButton:SetText(CUSTOMIZE);
		CharacterCreateNameEdit:Hide();
		CharacterCreateRandomName:Hide();

		--back to awesome gear
		C_CharacterCreation.SetSelectedPreviewGearType(1);

		-- back to normal camera
		C_CharacterCreation.SetFaceCustomizeCamera(false, false);
	end
end

function CharacterCreate_Forward()
	local stateIndex = CharacterCreate_GetCurrentStateIndex();

	if stateIndex + 1 > CharacterCreate_GetNumStates() then
		CreateCharacter();
		return;
	end

	CharacterCreateFrame.state = CHARACTER_CREATE_STATES[stateIndex + 1];

	if CharacterCreateFrame.state == "CUSTOMIZATION" then
		PlaySound(SOUNDKIT.GS_CHARACTER_SELECTION_CREATE_NEW);
		CharacterCreateClassFrame:Hide();
		CharacterCreateRaceFrame:Hide();
		CharacterCreateMoreInfoButton:Hide();
		CharacterCustomizationFrame:Show();
		CharacterCreatePreviewFrame:Show();
		CharacterTemplateConfirmDialog:Hide();

		CharacterCreate_PrepPreviewModels();
		if ( CharacterCreateFrame.customizationType ) then
			CharacterCreate_ResetFeaturesDisplay();
		else
			CharacterCreate_SelectCustomizationType(1);
		end

		CharCreateOkayButton:SetText(FINISH);
		CharacterCreateNameEdit:Show();
		if ( ALLOW_RANDOM_NAME_BUTTON ) then
			CharacterCreateRandomName:Show();
		end

		--You just went to customization mode - show the boring start gear
		C_CharacterCreation.SetSelectedPreviewGearType(0);

		-- set cam
		if (CharacterCreateFrame.customizationType and CharacterCreateFrame.customizationType > 1) then
			C_CharacterCreation.SetFaceCustomizeCamera(true, false);
		else
			C_CharacterCreation.SetFaceCustomizeCamera(false, false);
		end
	end
end

function CreateCharacter()
	PlaySound(SOUNDKIT.GS_CHARACTER_CREATION_CREATE_CHAR);

	-- CLASS-36892: Fixes self found state in CPP mismatching the UI
	if CharacterCreateSelfFound then
		C_CharacterCreation.ToggleSelfFoundMode(CharacterCreateSelfFound:GetChecked());
	end

	if CharacterCreateFrame.paidServiceType then
		GlueDialog_Show("CONFIRM_PAID_SERVICE");
	elseif CharacterCreateFrame.vasType == Enum.ValueAddedServiceType.PaidFactionChange or CharacterCreateFrame.vasType == Enum.ValueAddedServiceType.PaidRaceChange then
		GlueDialog_Show("CONFIRM_VAS_FACTION_CHANGE");
	elseif C_Reincarnation.IsReincarnating() then
		CharacterReincarnatePopUpDialog:ShowWarning();
	else
		if( Kiosk.IsEnabled() ) then
			KioskModeSplash:SetAutoEnterWorld(true);
		else
			KioskModeSplash:SetAutoEnterWorld(false)
		end

		local isPvP = select(2, GetServerName()); -- Grabbing whether we're a PvP realm from GetServerName()
		
		-- If using templates, pandaren must pick a faction.
		local _, faction = C_CharacterCreation.GetFactionForRace(CharacterCreate.selectedRace);

		if ( C_CharacterCreation.IsUsingCharacterTemplate() or C_CharacterCreation.IsForcingCharacterTemplate() ) and ( faction ~= "Alliance" and faction ~= "Horde" ) then
			CharacterTemplateConfirmDialog:Show();	
		elseif (HardcorePopUpFrame and C_GameRules.IsHardcoreActive()) then
			HardcorePopUpFrame:ShowCharacterCreationWarning();
		elseif (RealmWarningPopUpFrame and isPvP == true) then
			RealmWarningPopUpFrame:ShowCharacterCreationWarning();
		else
			C_CharacterCreation.CreateCharacter(CharacterCreateNameEdit:GetText());
		end
	end
end

function CharacterClass_OnClick(self, id)
	PlaySound(SOUNDKIT.GS_CHARACTER_CREATION_CLASS);
	C_CharacterCreation.SetSelectedClass(id);
	SetCharacterClass(id);
	if (SHOW_UNAVAILABLE_CLASSES) then
		SetCharacterRace(C_CharacterCreation.GetSelectedRace());
	end
end

function CharacterRace_OnClick(self, id)
	PlaySound(SOUNDKIT.GS_CHARACTER_CREATION_CLASS);
	if ( C_CharacterCreation.GetSelectedRace() == id ) then
		self:SetChecked(1);
		return;
	end
	C_CharacterCreation.SetSelectedRace(id);
	SetCharacterRace(id);
	C_CharacterCreation.SetSelectedSex(C_CharacterCreation.GetSelectedSex());
	C_CharacterCreation.SetCharacterCreateFacing(-15);
end

function CharacterCustomization_Left(id)
	PlaySound(SOUNDKIT.GS_CHARACTER_CREATION_LOOK);
	C_CharacterCreation.CycleCharCustomization(id, -1);
end

function CharacterCustomization_Right(id)
	PlaySound(SOUNDKIT.GS_CHARACTER_CREATION_LOOK);
	C_CharacterCreation.CycleCharCustomization(id, 1);
end

function CharacterCreate_GenerateRandomName(button)
	button:Disable();
	CharacterCreateNameEdit:SetText("...");
	C_CharacterCreation.RequestRandomName();
end

function CharacterCreate_Randomize()
	PlaySound(SOUNDKIT.GS_CHARACTER_CREATION_LOOK);
	C_CharacterCreation.RandomizeCharCustomization();

	if CharacterCreate_ResetFeaturesDisplay then
		CharacterCreate_ResetFeaturesDisplay();
	end
end

function CharacterCreate_RotatePreviews()
	if ( CharacterCreatePreviewFrame and CharacterCreatePreviewFrame:IsShown() ) then
		local facing = ((C_CharacterCreation.GetCharacterCreateFacing()) / -180) * math.pi;
		local previews = CharacterCreatePreviewFrame.previews;
		for index = CharacterCreatePreviewFrame.selectionIndex - 3, CharacterCreatePreviewFrame.selectionIndex + 3 do
			local previewFrame = previews[index];
			if ( previewFrame and previewFrame.model:HasCustomCamera() ) then
				previewFrame.model:SetCameraFacing(facing);
			end
		end
	end
end

function CharacterCreateRotateRight_OnUpdate(self)
	if ( self:GetButtonState() == "PUSHED" ) then
		C_CharacterCreation.SetCharacterCreateFacing(C_CharacterCreation.GetCharacterCreateFacing() + CHARACTER_FACING_INCREMENT);
		CharacterCreate_RotatePreviews();
	end
end

function CharacterCreateRotateLeft_OnUpdate(self)
	if ( self:GetButtonState() == "PUSHED" ) then
		C_CharacterCreation.SetCharacterCreateFacing(C_CharacterCreation.GetCharacterCreateFacing() - CHARACTER_FACING_INCREMENT);
		CharacterCreate_RotatePreviews();
	end
end

function CharacterCreate_UpdateCustomizationOptions()
	for i=Enum.CharCustomizationTypeMeta.MinValue, NUM_CHAR_CUSTOMIZATIONS-1 do
		_G["CharacterCustomizationButtonFrame"..(i+1).."Text"]:SetText(C_CharacterCreation.GetCustomizationDetails(i));
	end
end

function CharacterCreate_getRandomValidRace()
	local races = C_CharacterCreation.GetAvailableRaces();
	local validRaces = {};
	local validItr = 1;
	for index, raceData in pairs(races) do
		local button = _G["CharacterCreateRaceButton"..index];
		if(button:IsEnabled()) then
			validRaces[validItr] = button.raceID;
			validItr = validItr + 1;
		end
	end

	local validRace = 1;
	if(#validRaces > 0) then
		validRace = validRaces[math.random(1, #validRaces)];
	end

	return validRace;
end

function CharacterCreate_getRandomValidClass()
	local classes = C_CharacterCreation.GetAvailableClasses();
	local validClasses = {};
	local validItr = 1;
	for index, classData in pairs(classes) do
		local button = _G["CharacterCreateClassButton"..index];
		if(button:IsEnabled()) then
			validClasses[validItr] = button.classID;
			validItr = validItr + 1;
		end
	end

	local validClass = 1;
	if(#validClasses > 0) then
		validClass = validClasses[math.random(1, #validClasses)];
	end

	return validClass;
end

function SetDefaultRace()
	local defaultRace = C_CharacterCreation.GetSelectedRace();
	if (defaultRace > 0 ) then
		if(not CharacterCreate_isRaceEnabled(defaultRace)) then
			defaultRace = CharacterCreate_getRandomValidRace();
			C_CharacterCreation.SetSelectedRace(defaultRace);
		end
		SetCharacterRace(defaultRace);
	end
end

function GetDefaultClass()
	local classData = C_CharacterCreation.GetSelectedClass();
	local classID = classData.classID;
	if (not CharacterCreate_isClassEnabled(classID)) then
		classID = CharacterCreate_getRandomValidClass();
	end

	return classID;
end

function CharacterCreate_isRaceEnabled(race)
	local races = C_CharacterCreation.GetAvailableRaces();
	for index, raceData in pairs(races) do
		local button = _G["CharacterCreateRaceButton"..index];
		if(button.raceID == race) then
			return button:IsEnabled();
		end
	end

	return false;
end

function CharacterCreate_isClassEnabled(class)
	local classes = C_CharacterCreation.GetAvailableClasses();
	for index, classData in pairs(classes) do
		local button = _G["CharacterCreateClassButton"..index];
		if(button.classID == class) then
			return button:IsEnabled();
		end
	end

	return false;
end
CharacterCreateScrollFrameMixin = {};

function CharacterCreateScrollFrameMixin:OnLoad()
	CharacterCreateRaceScrollFrameScrollBar:ClearAllPoints();
	CharacterCreateRaceScrollFrameScrollBar:SetPoint("TOPLEFT", CharacterCreateRaceScrollFrame, "TOPRIGHT", 7, 4);
	CharacterCreateRaceScrollFrameScrollBar:SetPoint("BOTTOMLEFT", CharacterCreateRaceScrollFrame, "BOTTOMRIGHT", 7, 12);
	GlueScrollFrame_OnScrollRangeChanged(self);
end

function CharacterCreateScrollFrameMixin:OnScrollRangeChanged(xrange, yrange)
	GlueScrollFrame_OnScrollRangeChanged(self, yrange);
end
