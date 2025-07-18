MAX_CHARACTERS_DISPLAYED = 11;

CHARACTER_LIST_OFFSET = 0;

CHARACTER_SELECT_BACK_FROM_CREATE = false;

MOVING_TEXT_OFFSET = 12;
DEFAULT_TEXT_OFFSET = 0;
CHARACTER_BUTTON_HEIGHT = 57;
CHARACTER_LIST_TOP = 688;
AUTO_DRAG_TIME = 0.5;				-- in seconds

CHARACTER_UNDELETE_COOLDOWN = 0;	-- in seconds
CHARACTER_UNDELETE_COOLDOWN_REMAINING = 0; -- in seconds

PAID_CHARACTER_CUSTOMIZATION = 1;
PAID_RACE_CHANGE = 2;
PAID_FACTION_CHANGE = 3;
PAID_CHARACTER_CLONE = 4;

INFO_PANE_MAX_SCALE = 0.75;
CHOICE_PANE_MAX_SCALE = 0.75;

local ADDON_LIST_RECEIVED = false;
local ACCOUNT_SAVE_IS_LOADED = false;
CAN_BUY_RESULT_FOUND = false;
TOKEN_COUNT_UPDATED = false;
REALM_CHANGE_IS_AUTO = false;

CharacterSelectLockedButtonMixin = {};

local localizedAtlasMembers = {};

function GenerateBuildString(buildNumber)
	if buildNumber == 0 then
		return "No Login";
	end

	-- Generate Build String from the Integer.
	local versionParse = {tostring(buildNumber):match("(%d+)(%d%d)(%d%d)$")};

	if #versionParse > 0 then
		for k, v in ipairs(versionParse) do
			versionParse[k] = tonumber(v);
		end

		return table.concat(versionParse, ".");
	else
		return "OLD";
	end
end

function CharacterSelectLockedButtonMixin:OnEnter()
	local requiresPurchase = IsExpansionTrialCharacter(self.guid) and CanUpgradeExpansion() or not C_CharacterServices.HasRequiredBoostForUnrevoke();

    local tooltipFooter = nil;

	if not IsCharacterVASLocked(self.guid) then
		if requiresPurchase then
			tooltipFooter = CHARACTER_SELECT_REVOKED_BOOST_TOKEN_LOCKED_TOOLTIP_HELP_SHOP;
		else
			tooltipFooter = CHARACTER_SELECT_REVOKED_BOOST_TOKEN_LOCKED_TOOLTIP_HELP_USE_BOOST;
		end
	end

    -- TODO: Add color constants to glue?
    GlueTooltip:SetText(self.tooltipTitle, 1, 1, 1, 1, false);
    GlueTooltip:AddLine(self.tooltipText, nil, nil, nil, nil, true);
	if tooltipFooter then
		GlueTooltip:AddLine(tooltipFooter, .1, 1, .1, 1, true);
	end

    if not self.characterSelectButton.isAccountLocked then
        if requiresPurchase then
            tooltipFooter = CHARACTER_SELECT_REVOKED_BOOST_TOKEN_LOCKED_TOOLTIP_HELP_SHOP;
        else
            tooltipFooter = CHARACTER_SELECT_REVOKED_BOOST_TOKEN_LOCKED_TOOLTIP_HELP_USE_BOOST;
        end
    end

    GlueTooltip:SetOwner(self.TooltipAnchor, "ANCHOR_LEFT", 0, 0);
    GameTooltip_SetTitle(GlueTooltip, self.tooltipTitle, nil, false);
    GameTooltip_AddColoredLine(GlueTooltip, self.tooltipText, self.tooltipTextColor, nil, true);
    GameTooltip_AddDisabledLine(GlueTooltip, tooltipFooter);
    GlueTooltip:Show();
end

function CharacterSelectLockedButtonMixin:OnLeave()
    GlueTooltip:Hide();
end

function CharacterSelectLockedButtonMixin:OnClick()
    local isAccountLocked = self.characterSelectButton.isAccountLocked;

	if not isAccountLocked and IsExpansionTrialCharacter(self.guid) and CanUpgradeExpansion() then
		ToggleStoreUI();
		StoreFrame_SetGamesCategory();
		return;
	end

    CharacterSelectButton_OnClick(self.characterSelectButton);

    if isAccountLocked then
        return;
    end

	if GlobalGlueContextMenu_GetOwner() == self then
		GlobalGlueContextMenu_Release();
	else
		local availableBoostTypes = GetAvailableBoostTypesForCharacterByGUID(self.guid);
		if #availableBoostTypes > 1 then
			local glueContextMenu = GlobalGlueContextMenu_Acquire(self);
			glueContextMenu:SetPoint("TOPRIGHT", self, "TOPLEFT", 15, -12);

			for i, boostType in ipairs(availableBoostTypes) do
				local flowData = C_CharacterServices.GetCharacterServiceDisplayData(boostType);
				local function CharacterSelectLockedButtonContextMenuButton_OnClick() CharacterUpgradePopup_BeginCharacterUpgradeFlow(flowData, self.guid); end;
				glueContextMenu:AddButton(CHARACTER_SELECT_PADLOCK_DROP_DOWN_USE_BOOST:format(flowData.flowTitle), CharacterSelectLockedButtonContextMenuButton_OnClick);
			end

			local function CloseContextMenu()
				GlobalGlueContextMenu_Release();
			end

			glueContextMenu:AddButton(CANCEL, CloseContextMenu);

			glueContextMenu:Show();
		elseif #availableBoostTypes == 1 then
			local flowData = C_CharacterServices.GetCharacterServiceDisplayData(availableBoostTypes[1]);
			CharacterUpgradePopup_BeginCharacterUpgradeFlow(flowData, self.guid);
		else
			CharacterSelect_ShowBoostUnlockDialog(self.guid);
		end
	end
end

local function ShouldShowHighResButton()
	return AreHighResTexturesAvailable() and not C_BattleNet.AreHighResTexturesInstalled();
end

function CharacterSelectStoreButton_OnLoad(self)
	local fontString = self:GetFontString();
	fontString:SetPoint("CENTER", 8, 2);
	self.Logo:ClearAllPoints();
	self.Logo:SetPoint("RIGHT", fontString, "LEFT", -2, 0);

	-- Store button is repositioned depending on if CharacterSelectHighResButton is going to be shown
	if ShouldShowHighResButton() then
		StoreButton:SetPoint("BOTTOM", CharacterSelectAddonsButton, "TOP", 1, 32);
	else
		StoreButton:SetPoint("BOTTOM", CharacterSelectAddonsButton, "TOP", 1, 2);
	end
end

function CharacterSelectHighResButton_OnLoad(self)
	self:SetShown(ShouldShowHighResButton());
end

function CharacterSelectHighResButton_OnShow(self)
	local version = GetBuildInfo();
	local showGlow = (version == "4.4.1") and GetCVar("hasDeclinedHighResTextures") == "0";
	self.Glow:SetShown(showGlow);
	self.New:SetShown(showGlow);
end

function CharacterSelectHighResButton_OnEnter(self)
    GlueTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, -20);
    GlueTooltip:AddLine(HD_TEXTURES_BUTTON, 1.0, 1.0, 1.0);
    GlueTooltip:AddLine(HD_TEXTURES_BUTTON_TOOLTIP, nil, nil, nil, 1, 1);
    GlueTooltip:Show();
end

function CharacterSelectHighResButton_OnLeave(self)
    GlueTooltip:Hide();
end

function CharacterSelectHighResButton_OnClick(self)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	CharacterSelect_OpenDownloadHighResDialog();
end

function CharacterSelect_OpenDownloadHighResDialog()
	GlueDialog_Show("CHARACTER_SELECT_DOWNLOAD_HIGH_RES_TEXTURES");
end

StaticPopupDialogs["CHARACTER_SELECT_DOWNLOAD_HIGH_RES_TEXTURES"] = {
    text = IsMacClient() and HD_TEXTURES_DLG_TEXT_MAC or HD_TEXTURES_DLG_TEXT,
    button1 = IsMacClient() and HD_TEXTURES_DLG_ACCEPT_MAC or HD_TEXTURES_DLG_ACCEPT,
    button2 = CANCEL,
    escapeHides = true,
	OnAccept = function()
		C_BattleNet.InstallHighResTextures();
	end,
	OnCancel = function()
		SetCVar("hasDeclinedHighResTextures", "1");
		CharacterSelectHighResButton.Glow:Hide();
		CharacterSelectHighResButton.New:Hide();
	end,
};

function CharacterSelect_OnLoad(self)
    CharacterSelectModel:SetSequence(0);
    CharacterSelectModel:SetCamera(0);

    self.createIndex = 0;
    self.selectedIndex = 0;
    self.selectLast = false;
	self.waitingForCharacterList = true;
	self.showSocialContract = false;
    self.characterPadlockPool = CreateFramePool("BUTTON", self, "CharSelectLockedButtonTemplate");
    self:RegisterEvent("CHARACTER_LIST_UPDATE");
    self:RegisterEvent("UPDATE_SELECTED_CHARACTER");
    self:RegisterEvent("FORCE_RENAME_CHARACTER");
    self:RegisterEvent("CHAR_RENAME_IN_PROGRESS");
    self:RegisterEvent("STORE_STATUS_CHANGED");
    self:RegisterEvent("CHARACTER_UNDELETE_STATUS_CHANGED");
    self:RegisterEvent("CLIENT_FEATURE_STATUS_CHANGED");
	self:RegisterEvent("CHARACTER_COPY_STATUS_CHANGED")
    self:RegisterEvent("CHARACTER_UNDELETE_FINISHED");
    self:RegisterEvent("TOKEN_CAN_VETERAN_BUY_UPDATE");
    self:RegisterEvent("TOKEN_DISTRIBUTIONS_UPDATED");
    self:RegisterEvent("TOKEN_MARKET_PRICE_UPDATED");
    self:RegisterEvent("VAS_CHARACTER_STATE_CHANGED");
    self:RegisterEvent("STORE_PRODUCTS_UPDATED");
    self:RegisterEvent("CHARACTER_DELETION_RESULT");
    self:RegisterEvent("CHARACTER_DUPLICATE_LOGON");
    self:RegisterEvent("CHARACTER_LIST_RETRIEVING");
    self:RegisterEvent("CHARACTER_LIST_RETRIEVAL_RESULT");
    self:RegisterEvent("DELETED_CHARACTER_LIST_RETRIEVING");
    self:RegisterEvent("DELETED_CHARACTER_LIST_RETRIEVAL_RESULT");
    self:RegisterEvent("VAS_CHARACTER_QUEUE_STATUS_UPDATE");
    self:RegisterEvent("LOGIN_STATE_CHANGED");
	self:RegisterEvent("UPDATE_EXPANSION_LEVEL");
	self:RegisterEvent("TRIAL_STATUS_UPDATE");
    self:RegisterEvent("CHARACTER_UPGRADE_UNREVOKE_RESULT");
	self:RegisterEvent("MIN_EXPANSION_LEVEL_UPDATED");
	self:RegisterEvent("MAX_EXPANSION_LEVEL_UPDATED");
	self:RegisterEvent("INITIAL_HOTFIXES_APPLIED");
	self:RegisterEvent("UPDATE_NAME_RESERVATION");
	self:RegisterEvent("SOCIAL_CONTRACT_STATUS_UPDATE");
    self:RegisterEvent("ACCOUNT_SAVE_ENABLED_UPDATE");
    self:RegisterEvent("ACCOUNT_LOCKED_POST_SAVE_UPDATE");
	self:RegisterEvent("NAV_BAR_ENABLED_CHANGED");
    SetCharSelectModelFrame("CharacterSelectModel");

    CHARACTER_SELECT_BACK_FROM_CREATE = false;

    CHARACTER_LIST_OFFSET = 0;

	CharacterSelect_RefreshNavBarEnabledState();
end

local translationTable = { };	-- for character reordering: key = button index, value = character ID
VAS_QUEUE_TIMES = {};
function CharacterSelect_OnEvent(self, event, ...)
    if ( event == "CHARACTER_LIST_UPDATE" ) then
        PromotionFrame_AwaitingPromotion();

        local listSize = ...;
        if ( listSize ) then
            table.wipe(translationTable);
            for i = 1, listSize do
                tinsert(translationTable, i);
            end
            CharacterSelect.orderChanged = nil;
        end
        local numChars = GetNumCharacters();
        if (self.undeleting and numChars == 0) then
            CharacterSelect_EndCharacterUndelete();
            self.undeleteNoCharacters = true;
            return;
        elseif (not CHARACTER_SELECT_BACK_FROM_CREATE and numChars == 0) then
			local connectedToWoW = select(2, C_Login.GetState());
			if not connectedToWoW then
				-- If we're disconnected, don't change screens. We either DC'd or are switching realms and will get a new character list soon.
				return;
			end

            if (IsKioskGlueEnabled()) then
                GlueParent_SetScreen("kioskmodesplash");
            elseif not IsWowTokenLimitedModeEnabled() then
                GlueParent_SetScreen("charcreate");
            end
            return;
        end

        CHARACTER_SELECT_BACK_FROM_CREATE = false;

        if (self.hasPendingTrialBoost) then
            KioskMode_SetWaitingOnTrial(true);
            C_CharacterServices.TrialBoostCharacter(self.trialBoostGuid, self.trialBoostFactionID, self.trialBoostSpecID);
            CharacterSelect_SetPendingTrialBoost(false);
        end

        if (self.undeleteNoCharacters) then
            GlueDialog_Show("UNDELETE_NO_CHARACTERS");
            self.undeleteNoCharacters = false;
        end

		self.waitingForCharacterList = false;
        UpdateCharacterList();
        UpdateAddonButton(true);
        CharSelectCharacterName:SetText(GetCharacterInfo(GetCharIDFromIndex(self.selectedIndex)));
        KioskMode_CheckAutoRealm();
        KioskMode_CheckEnterWorld();
        CharacterServicesMaster_OnCharacterListUpdate();
    elseif ( event == "UPDATE_SELECTED_CHARACTER" ) then
        local charID = ...;
        if ( charID == 0 ) then
            CharSelectCharacterName:SetText("");
        else
            local index = GetIndexFromCharID(charID);
            self.selectedIndex = index;
            CharSelectCharacterName:SetText(GetCharacterInfo(charID));
        end
        if ((CHARACTER_LIST_OFFSET == 0) and (self.selectedIndex > MAX_CHARACTERS_DISPLAYED)) then
            CHARACTER_LIST_OFFSET = self.selectedIndex - MAX_CHARACTERS_DISPLAYED;
        end
        UpdateCharacterSelection(self);
	elseif ( event == "UPDATE_NAME_RESERVATION" ) then
		CharacterSelect_UpdateButtonState();
    elseif ( event == "FORCE_RENAME_CHARACTER" ) then
        GlueDialog_Hide();
        local message = ...;
        CharacterRenameDialog:Show();
        CharacterRenameText1:SetText(_G[message]);
    elseif ( event == "CHAR_RENAME_IN_PROGRESS" ) then
        GlueDialog_Show("OKAY", CHAR_RENAME_IN_PROGRESS);
    elseif ( event == "STORE_STATUS_CHANGED" ) then
        if (ADDON_LIST_RECEIVED) then
            CharacterSelect_UpdateStoreButton();
        end
    elseif ( event == "CHARACTER_UNDELETE_STATUS_CHANGED") then
        UpdateCharacterUndeleteStatus();
    elseif ( event == "CLIENT_FEATURE_STATUS_CHANGED" ) then
        AccountUpgradePanel_Update(CharSelectAccountUpgradeButton.isExpanded);
		CopyCharacterButton_UpdateButtonState();
		UpdateCharacterList();
	elseif ( event == "CHARACTER_COPY_STATUS_CHANGED" ) then
		CopyCharacterButton_UpdateButtonState();
    elseif ( event == "CHARACTER_UNDELETE_FINISHED" ) then
        GlueDialog_Hide("UNDELETING_CHARACTER");
        CharacterSelect_EndCharacterUndelete();
        local result, guid = ...;

        if ( result == LE_CHARACTER_UNDELETE_RESULT_OK ) then
            self.undeleteGuid = guid;
            self.undeleteFailed = nil;
        else
            self.undeleteGuid = nil;
			if ( result == LE_CHARACTER_UNDELETE_RESULT_ERROR_PVP_TEAMS_VIOLATION ) then
				self.undeleteFailed = "pvp";
			elseif ( result == LE_CHARACTER_UNDELETE_RESULT_ERROR_NAME_TAKEN_BY_THIS_ACCOUNT ) then
                self.undeleteFailed = "name";
			elseif ( result == LE_CHARACTER_UNDELETE_RESULT_ERROR_DEATHKNIGHT_LEVEL_REQUIREMENT ) then
				self.undeleteFailed = "deathknight";
            else
                self.undeleteFailed = "other";
            end
        end
    elseif ( event == "TOKEN_DISTRIBUTIONS_UPDATED" ) then
        local result = ...;
        -- TODO: Use lua enum
        if (result == 1) then
            TOKEN_COUNT_UPDATED = true;
            CharacterSelect_CheckVeteranStatus();
        end
    elseif ( event == "TOKEN_CAN_VETERAN_BUY_UPDATE" ) then
        local result = ...;
        CAN_BUY_RESULT_FOUND = result;
        CharacterSelect_CheckVeteranStatus();
    elseif ( event == "TOKEN_MARKET_PRICE_UPDATED" ) then
        local result = ...;
        CharacterSelect_CheckVeteranStatus();
	elseif event == "VAS_CHARACTER_STATE_CHANGED" then
		CharacterSelect_UpdateIfUpdateIsNotPending();
	elseif event == "STORE_PRODUCTS_UPDATED" then
		CharacterSelect_UpdateIfUpdateIsNotPending();
    elseif ( event == "CHARACTER_DELETION_RESULT" ) then
        local success, errorToken = ...;
        if ( success ) then
            CHARACTER_LIST_OFFSET = 0;
            CharacterSelect_SelectCharacter(1, 1);
            GlueDialog_Hide();
        else
            GlueDialog_Show("OKAY", _G[errorToken]);
        end
    elseif ( event == "CHARACTER_DUPLICATE_LOGON" ) then
        local errorCode = ...;
        GlueDialog_Show("OKAY", _G[errorCode]);
    elseif ( event == "CHARACTER_LIST_RETRIEVING" ) then
        CharacterSelect_SetRetrievingCharacters(true);
    elseif ( event == "CHARACTER_LIST_RETRIEVAL_RESULT" ) then
        local success = ...;
        CharacterSelect_SetRetrievingCharacters(false, success);
		if( success ) then
			CharacterSelect_ShowSeasonNotification();
		end
    elseif ( event == "DELETED_CHARACTER_LIST_RETRIEVING" ) then
        CharacterSelect_SetRetrievingCharacters(true);
    elseif ( event == "DELETED_CHARACTER_LIST_RETRIEVAL_RESULT" ) then
        local success = ...;
        CharacterSelect_SetRetrievingCharacters(false, success);
    elseif ( event == "CHARACTER_UPGRADE_UNREVOKE_RESULT" ) then
        -- TODO: Add specific error messaging, but for now just show dialog that will open the help url
        local errorCode = ...
        if errorCode ~= 0 then
            local urlIndex = GetCurrentRegionName() == "CN" and 36 or 35;
            GlueDialog_Show("OKAY_WITH_URL_INDEX", ERROR_MANUAL_UNREVOKE_FAILURE, urlIndex);
        end
    elseif ( event == "VAS_CHARACTER_QUEUE_STATUS_UPDATE" ) then
        local guid, minutes = ...;
        VAS_QUEUE_TIMES[guid] = minutes;
		CharacterSelect_UpdateIfUpdateIsNotPending();
    elseif ( event == "LOGIN_STATE_CHANGED" ) then
        local FROM_LOGIN_STATE_CHANGE = true;
        CharacterSelect_UpdateState(FROM_LOGIN_STATE_CHANGE);
	elseif ( event == "TRIAL_STATUS_UPDATE" ) then
		AccountUpgradePanel_Update(CharSelectAccountUpgradeButton.isExpanded);
		UpdateCharacterList();
	elseif ( event == "UPDATE_EXPANSION_LEVEL" or event == "MIN_EXPANSION_LEVEL_UPDATED" or event == "MAX_EXPANSION_LEVEL_UPDATED" or event == "INITIAL_HOTFIXES_APPLIED" ) then
		AccountUpgradePanel_Update(CharSelectAccountUpgradeButton.isExpanded);
	elseif ( event == "SOCIAL_CONTRACT_STATUS_UPDATE") then
		self.showSocialContract = ...;
		if self.showSocialContract and GlueParent_GetCurrentScreen() == "charselect" then
			CharacterSelect_UpdateIfUpdateIsNotPending();
		end
    elseif ( event == "ACCOUNT_SAVE_ENABLED_UPDATE") then
        CharacterSelect_ConditionallyLoadAccountSaveUI();
    elseif ( event == "ACCOUNT_LOCKED_POST_SAVE_UPDATE") then
        CharacterSelect_UpdateIfUpdateIsNotPending();
	elseif ( event == "NAV_BAR_ENABLED_CHANGED" ) then
		CharacterSelect_RefreshNavBarEnabledState();
	end
end

function CharacterSelect_UpdateIfUpdateIsNotPending()
	if ( not IsCharacterListUpdatePending() ) then
		UpdateCharacterList();
	end
end

function CharacterSelect_RefreshNavBarEnabledState()
	if ( not CharacterSelectUI.VisibilityFramesContainer.NavBar ) then
		return;
	end

	CharacterSelectUI.useNavBar = IsNavBarEnabled();
	if CharacterSelectUI.useNavBar then
		CharacterSelectUI.VisibilityFramesContainer.NavBar:Show();
		CharacterSelectMenuButton:Hide();
		StoreButton:Hide();
	else
		CharacterSelectUI.VisibilityFramesContainer.NavBar:Hide();
		CharacterSelectMenuButton:Show();
		StoreButton:Show();
	end
end

function CharacterSelect_OnShow(self)

	MAX_CHARACTERS_DISPLAYED = CHARACTER_SELECT_MAX_CHARACTERS;

	CharacterSelectCharacterFrame:SetSize(260, CHARACTER_SELECT_HEIGHT);

    CharacterCreate_CancelReincarnation(); -- If we're back at this screen, we're not reincarnating
    InitializeCharacterScreenData();
    SetInCharacterSelect(true);
    CHARACTER_LIST_OFFSET = 0;
    CharacterSelect_ResetVeteranStatus();

    if ( #translationTable == 0 ) then
        for i = 1, GetNumCharacters() do
            tinsert(translationTable, i);
        end
    end

    -- request account data times from the server (so we know if we should refresh keybindings, etc...)
    CheckCharacterUndeleteCooldown();

    UpdateAddonButton();

    CharacterSelect_SetAutoSwitchRealm(false);

    local FROM_LOGIN_STATE_CHANGE = false;
    CharacterSelect_UpdateState(FROM_LOGIN_STATE_CHANGE);

	-- If for any reason we had the UI disabled, turn it back on.
	CharacterSelectUI:ResetVisibilityState();

    -- Gameroom billing stuff (For Korea and China only)
    if ( SHOW_GAMEROOM_BILLING_FRAME ) then
        local paymentPlan, hasFallBackBillingMethod, isGameRoom = GetBillingPlan();
        if ( paymentPlan == 0 or ( ( paymentPlan == 1 or paymentPlan == 3 ) and ONLY_SHOW_GAMEROOM_BILLING_FRAME_ON_PERSONAL_TIME ) ) then
            -- No payment plan or should only show when using consumption time
            GameRoomBillingFrame:Hide();
        else
            local billingTimeLeft = GetBillingTimeRemaining();
            -- Set default text for the payment plan
            local billingText = _G["BILLING_TEXT"..paymentPlan];
            if ( paymentPlan == 1 ) then
                -- Recurring account
                billingTimeLeft = ceil(billingTimeLeft/(60 * 24));
                if ( billingTimeLeft == 1 ) then
                    billingText = BILLING_TIME_LEFT_LAST_DAY;
                end
            elseif ( paymentPlan == 2 ) then
                -- Free account
                if ( billingTimeLeft < (24 * 60) ) then
                    billingText = format(BILLING_FREE_TIME_EXPIRE, format(MINUTES_ABBR, billingTimeLeft));
                end
            elseif ( paymentPlan == 3 ) then
                -- Fixed but not recurring
                if ( isGameRoom == 1 ) then
                    if ( billingTimeLeft <= 30 ) then
                        billingText = BILLING_GAMEROOM_EXPIRE;
                    else
                        billingText = format(BILLING_FIXED_IGR, MinutesToTime(billingTimeLeft, 1));
                    end
                else
                    -- personal fixed plan
                    if ( billingTimeLeft < (24 * 60) ) then
                        billingText = BILLING_FIXED_LASTDAY;
                    else
                        billingText = format(billingText, MinutesToTime(billingTimeLeft));
                    end
                end
            elseif ( paymentPlan == 4 ) then
                -- Usage plan
                if ( isGameRoom == 1 ) then
                    -- game room usage plan
                    if ( billingTimeLeft <= 600 ) then
                        billingText = BILLING_GAMEROOM_EXPIRE;
                    else
                        billingText = BILLING_IGR_USAGE;
                    end
                else
                    -- personal usage plan
                    if ( billingTimeLeft <= 30 ) then
                        billingText = BILLING_TIME_LEFT_30_MINS;
                    else
                        billingText = format(billingText, billingTimeLeft);
                    end
                end
            end
            -- If fallback payment method add a note that says so
            if ( hasFallBackBillingMethod == 1 ) then
                billingText = billingText.."\n\n"..BILLING_HAS_FALLBACK_PAYMENT;
            end
            GameRoomBillingFrameText:SetText(billingText);
            GameRoomBillingFrame:SetHeight(GameRoomBillingFrameText:GetHeight() + 26);
            GameRoomBillingFrame:Show();
        end
    end

    -- fadein the character select ui
    CharacterSelectUI.FadeIn:Play();

    --Clear out the addons selected item
    AddonList_ClearCharacterDropdown();

    AccountUpgradePanel_Update(CharSelectAccountUpgradeButton.isExpanded);

    if( IsKioskGlueEnabled() ) then
        CharacterSelectUI:Hide();
    end

    -- character templates
    CharacterTemplatesFrame_Update();

    PlayersOnServer_Update();

    CharacterSelect_UpdateStoreButton();

    CharacterServicesMaster_UpdateServiceButton();

    C_StoreSecure.GetPurchaseList();
    C_StoreSecure.GetProductList();
    C_StoreGlue.UpdateVASPurchaseStates();

    CharacterSelect_ConditionallyLoadAccountSaveUI();

    CharacterSelectServerAlert_UpdateEnabled();

    CharacterSelect_CheckVeteranStatus();

    if (C_StoreGlue.GetDisconnectOnLogout()) then
        C_StoreSecure.SetDisconnectOnLogout(false);
        GlueDialog_Hide();
        C_Login.DisconnectFromServer();
    end

    if (not HasCheckedSystemRequirements()) then
        CheckSystemRequirements();
        SetCheckedSystemRequirements(true);
    end

	if not self.showSocialContract then
		C_SocialContractGlue.GetShouldShowSocialContract();
	end

	local includeSeenWarnings = true;
	CharacterSelectUI.VisibilityFramesContainer.ConfigurationWarnings:SetShown(#C_ConfigurationWarnings.GetConfigurationWarnings(includeSeenWarnings) > 0);
end

function CharacterSelect_OnHide(self)
    -- the user may have gotten d/c while dragging
    if ( CharacterSelect.draggedIndex ) then
        local button = _G["CharSelectCharacterButton"..(CharacterSelect.draggedIndex - CHARACTER_LIST_OFFSET)];
        CharacterSelectButton_OnDragStop(button);
    end
    CharacterSelect_SaveCharacterOrder();
    CharacterDeleteDialog:Hide();
    CharacterRenameDialog:Hide();
    AccountReactivate_CloseDialogs();

    if ( DeclensionFrame ) then
        DeclensionFrame:Hide();
    end

    PromotionFrame_Hide();
    C_AuthChallenge.Cancel();
    if ( StoreFrame ) then
        StoreFrame:Hide();
    end
    CopyCharacterFrame:Hide();
    if ( AddonDialog:IsShown() ) then
        AddonDialog:Hide();
        HasShownAddonOutOfDateDialog = false;
    end

    if ( self.undeleting ) then
        CharacterSelect_EndCharacterUndelete();
    end

    if ( CharSelectServicesFlowFrame:IsShown() ) then
        CharSelectServicesFlowFrame:Hide();
    end

	SocialContractFrame:Hide();

    AccountReactivate_CloseDialogs();
    SetInCharacterSelect(false);

	GlowEmitterFactory:Hide(CharSelectChangeRealmButton);
end

function CharacterSelect_GetCharacterListUpdate()
	CharacterSelect.waitingForCharacterList = true;
	GetCharacterListUpdate();
end

function CharacterSelect_SetAutoSwitchRealm(isAuto)
    REALM_CHANGE_IS_AUTO = isAuto;
end

function CharacterSelect_UpdateState(fromLoginState)
    local serverName, isPVP, isRP = GetServerName();
    local connected = IsConnectedToServer();
    local serverType = "";
    if ( serverName ) then
        if( not connected ) then
            serverName = serverName.."\n("..SERVER_DOWN..")";
        end
        if ( isPVP ) then
            if ( isRP ) then
                serverType = RPPVP_PARENTHESES;
            else
                serverType = PVP_PARENTHESES;
            end
        elseif ( isRP ) then
            serverType = RP_PARENTHESES;
        end
        CharSelectRealmName:SetText(serverName.." "..serverType);
        CharSelectRealmName:Show();
    else
        CharSelectRealmName:Hide();
    end

    if (fromLoginState == REALM_CHANGE_IS_AUTO) then
        if ( connected ) then
            if (fromLoginState) then
                if (IsKioskGlueEnabled()) then
                    GlueParent_SetScreen("kioskmodesplash");
                else
                    CharacterSelectUI:Hide();
                    CharacterSelectUI:Show();
                end
            end
			if (not IsCharacterListUpdateRequested()) then
	            CharacterSelect_GetCharacterListUpdate();
			end
        else
            UpdateCharacterList();
        end
    end
end

function CharacterSelect_SaveCharacterOrder()
    if ( CharacterSelect.orderChanged ) then
        SaveCharacterOrder(translationTable);
        CharacterSelect.orderChanged = nil;
    end
end

-- This hack enables shared code to call this Mainline API despite Classic not implementing it.
CharacterSelectListUtil = {};
CharacterSelectListUtil.SaveCharacterOrder = CharacterSelect_SaveCharacterOrder;

function CharacterSelect_SetRetrievingCharacters(retrieving, success)
    if ( retrieving ~= CharacterSelect.retrievingCharacters ) then
        CharacterSelect.retrievingCharacters = retrieving;

        if ( retrieving ) then
			-- Do not stop showing the login queue dialog if currently showing.
			local visibleGlueDialog = GlueDialog_GetVisible();
			if ( visibleGlueDialog ~= "QUEUED_WITH_FCM" and visibleGlueDialog ~= "QUEUED_NORMAL" ) then
				GlueDialog_Show("RETRIEVING_CHARACTER_LIST");
			end
        else
            if ( success ) then
                GlueDialog_Hide("RETRIEVING_CHARACTER_LIST");
            else
                GlueDialog_Show("OKAY", CHAR_LIST_FAILED);
            end
        end

        CharacterSelect_UpdateButtonState();
    end
end

function CharacterSelect_IsRetrievingCharacterList()
    return CharacterSelect.retrievingCharacters;
end

function CharacterSelect_IsVisible()
	return CharacterSelect:IsVisible();
end

function CharacterSelect_IsUndeleting()
	return CharacterSelect.undeleting;
end

function CharacterSelect_OnUpdate(self, elapsed)
    if ( self.undeleteFailed ) then
        if (not GlueDialog:IsShown()) then
			if ( self.undeleteFailed == "pvp" ) then
				GlueDialog_Show("UNDELETE_FAILED_PVP");
			elseif (self.undeleteFailed == "name") then
				GlueDialog_Show("UNDELETE_NAME_TAKEN");
			elseif (self.undeleteFailed == "deathknight") then
				GlueDialog_Show("UNDELETE_DEATHKNIGHT_LEVEL_REQUIREMENT");
			else
				GlueDialog_Show("UNDELETE_FAILED");
			end
			self.undeleteFailed = false;
        end
    end

    if ( self.undeleteSucceeded ) then
        if (not GlueDialog:IsShown()) then
            GlueDialog_Show(self.undeletePendingRename and "UNDELETE_SUCCEEDED_NAME_TAKEN" or "UNDELETE_SUCCEEDED");
            self.undeleteSucceeded = false;
            self.undeletePendingRename = false;
        end
    end

    if ( self.pressDownButton ) then
        self.pressDownTime = self.pressDownTime + elapsed;
        if ( self.pressDownTime >= AUTO_DRAG_TIME ) then
            CharacterSelectButton_OnDragStart(self.pressDownButton);
        end
    end

    if ( C_CharacterServices.HasQueuedUpgrade() or C_StoreGlue.GetVASProductReady() ) then
        CharacterServicesMaster_OnCharacterListUpdate();
    end

    if (StoreFrame_WaitingForCharacterListUpdate()) then
        StoreFrame_OnCharacterListUpdate();
    end

	GlueDialog_CheckQueuedDialogs();
end

function CharacterSelect_OnKeyDown(self,key)
    if ( key == "ESCAPE" ) then
        if not CharacterSelectUI:GetVisibilityState() then
			CharacterSelectUI:ToggleVisibilityState();
			return false;
        elseif (C_Login.IsLauncherLogin() ) then
            GlueMenuFrameUtil.ToggleMenu();
        elseif (CharSelectServicesFlowFrame:IsShown()) then
            CharSelectServicesFlowFrame:Hide();
        elseif ( CopyCharacterFrame:IsShown() ) then
            CopyCharacterFrame:Hide();
        elseif (CharacterSelect.undeleting) then
            CharacterSelect_EndCharacterUndelete();
		elseif ( GlobalGlueContextMenu_IsShown() ) then
			GlobalGlueContextMenu_Release();
        else
            CharacterSelect_Exit();
        end
    elseif ( key == "ENTER" ) then
        if (CharacterSelect_AllowedToEnterWorld()) then
            CharacterSelect_EnterWorld();
        end
    elseif ( key == "PRINTSCREEN" ) then
        Screenshot();
    elseif ( key == "UP" or key == "LEFT" ) then
        if (CharSelectServicesFlowFrame:IsShown()) then
            return;
        end
        CharacterSelectScrollUp_OnClick();
    elseif ( key == "DOWN" or key == "RIGHT" ) then
        if (CharSelectServicesFlowFrame:IsShown()) then
            return;
        end
        CharacterSelectScrollDown_OnClick();
	elseif key == "Z" and IsAltKeyDown() then
		CharacterSelectUI:ToggleVisibilityState();
		return false;
    end
end

function CharacterSelect_SetPendingTrialBoost(hasPendingTrialBoost, factionID, specID, guid)
    CharacterSelect.hasPendingTrialBoost = hasPendingTrialBoost;
    CharacterSelect.trialBoostFactionID = factionID;
    CharacterSelect.trialBoostSpecID = specID;
    CharacterSelect.trialBoostGuid = guid;
end

function CharacterSelect_SetupPadlockForCharacterButton(button, guid)
    local padlock = CharacterSelect.characterPadlockPool:Acquire();
    button.padlock = padlock;
    padlock.characterSelectButton = button;
    padlock.guid = guid;
    padlock.tooltipTextColor = NORMAL_FONT_COLOR;

    local isAccountLocked = CharacterSelect_IsAccountLocked();

    local isTrialBoost, isTrialBoostLocked, revokedCharacterUpgrade, _, _, _, isExpansionTrialCharacter = select(22, GetCharacterInfoByGUID(guid));
	if isAccountLocked then
        padlock.tooltipTitle = nil;
        padlock.tooltipText = CHARACTER_SELECT_ACCOUNT_LOCKED;
        padlock.tooltipTextColor = RED_FONT_COLOR;
	elseif isExpansionTrialCharacter then
		if IsExpansionTrial() or CanUpgradeExpansion() then
			-- Player has to upgrade to unlock this character
			padlock.tooltipTitle = CHARACTER_SELECT_INFO_EXPANSION_TRIAL_BOOST_LOCKED_TOOLTIP_TITLE;
			padlock.tooltipText = CHARACTER_SELECT_INFO_EXPANSION_TRIAL_BOOST_LOCKED_TOOLTIP_TEXT;
		else
			-- Player just needs to boost to get this character
			padlock.tooltipTitle = CHARACTER_SELECT_INFO_TRIAL_BOOST_LOCKED_TOOLTIP_TITLE;
			padlock.tooltipText = CHARACTER_SELECT_INFO_TRIAL_BOOST_LOCKED_TOOLTIP_TEXT;
		end
    elseif isTrialBoost and isTrialBoostLocked then
        padlock.tooltipTitle = CHARACTER_SELECT_INFO_TRIAL_BOOST_LOCKED_TOOLTIP_TITLE;
        padlock.tooltipText = CHARACTER_SELECT_INFO_TRIAL_BOOST_LOCKED_TOOLTIP_TEXT;
    elseif revokedCharacterUpgrade then
        padlock.tooltipTitle = CHARACTER_SELECT_REVOKED_BOOST_TOKEN_LOCKED_TOOLTIP_TITLE;
        padlock.tooltipText = CHARACTER_SELECT_REVOKED_BOOST_TOKEN_LOCKED_TOOLTIP_TEXT;
	elseif IsCharacterVASLocked(guid) then
		padlock.tooltipTitle = CHARACTER_SELECT_REVOKED_BOOST_TOKEN_LOCKED_TOOLTIP_TITLE;
    else
        GMError("Invalid lock type");
    end

    padlock:SetParent(button);
    padlock:SetPoint("TOPRIGHT", button, "TOPLEFT", 5, 12);

    padlock:SetShown(not CharSelectServicesFlowFrame:IsShown());
end

function CharacterSelect_UpdateModel(self)
    UpdateSelectionCustomizationScene();
    self:AdvanceTime();
end

function CharacterSelect_SetCharacterButtonEnabled(button, enabled)
	if enabled then
		button.buttonText.name:SetTextColor(1, 0.82, 0);
		button.buttonText.Info:SetTextColor(1, 1, 1);
		if button.coloredClassName then
			button.buttonText.Info:SetText(button.coloredClassName);
		end
		button.buttonText.Location:SetTextColor(0.5, 0.5, 0.5);
	else
		button.buttonText.name:SetTextColor(0.25, 0.25, 0.25);
		if button.uncoloredClassName then
			button.buttonText.Info:SetText(button.uncoloredClassName);
		end
		button.buttonText.Info:SetTextColor(0.25, 0.25, 0.25);
		button.buttonText.Location:SetTextColor(0.25, 0.25, 0.25);
	end

	button.buttonText.Info:SetFixedColor(not enabled);
	button:SetEnabled(enabled);
end

function CharacterSelect_HidePaidServiceButtons()
	local numDisplayedCharacters = math.min(GetNumCharacters(), MAX_CHARACTERS_DISPLAYED);

	for buttonIndex = 1, numDisplayedCharacters do
		_G["CharSelectPaidService"..buttonIndex]:Hide();
	end
end

function UpdateCharacterSelection(self)
    local button, paidServiceButton;

    for i=1, MAX_CHARACTERS_DISPLAYED, 1 do
        button = _G["CharSelectCharacterButton"..i];
        paidServiceButton = _G["CharSelectPaidService"..i];
        button:UnlockHighlight();
        button.upButton:Hide();
        button.downButton:Hide();
        if (self.undeleting or CharSelectServicesFlowFrame:IsShown()) then
            paidServiceButton:Hide();
            CharacterSelectButton_DisableDrag(button);

            if (button.padlock) then
                button.padlock:Hide();
            end
        else
            CharacterSelectButton_EnableDrag(button);
        end
		button.characterID = GetCharIDFromIndex(i + CHARACTER_LIST_OFFSET);
    end

    local index = self.selectedIndex - CHARACTER_LIST_OFFSET;
    if ( (index > 0) and (index <= MAX_CHARACTERS_DISPLAYED) ) then
        button = _G["CharSelectCharacterButton"..index];
        paidServiceButton = _G["CharSelectPaidService"..index];

        if ( button ) then
            button:LockHighlight();
            if ( button:IsMouseOver() ) then
                CharacterSelectButton_ShowMoveButtons(button);
            end
            if ( self.undeleting ) then
                paidServiceButton.GoldBorder:Hide();
                paidServiceButton.VASIcon:Hide();
                paidServiceButton.texture:SetTexCoord(.5, 1, .5, 1);
                paidServiceButton.texture:Show();
                paidServiceButton.tooltip = UNDELETE_SERVICE_TOOLTIP;
                paidServiceButton.disabledTooltip = nil;
                paidServiceButton:Show();
            end

            CharacterSelect_UpdateButtonState();
        end
    end

	if( CharacterServicesCharacterSelector ) then
		CharacterServicesCharacterSelector:Refresh();
	end
end

function UpdateCharacterList(skipSelect)
	if CharacterSelect.waitingForCharacterList then
		return;
	end

	if CharacterSelect.showSocialContract then
		SocialContractFrame:Show();
		CharacterSelect.showSocialContract = false;
	end

    local numChars = GetNumVisibleCharacters();
    local coords;

    if ( CharacterSelect.undeleteChanged ) then
        CHARACTER_LIST_OFFSET = 0;
        CharacterSelect.undeleteChanged = false;
    end

	if CharacterSelect.selectLast then
        CHARACTER_LIST_OFFSET = max(numChars - MAX_CHARACTERS_DISPLAYED, 0);
        CharacterSelect.selectedIndex = GetNumCharacters();
        CharacterSelect.selectLast = false;
	elseif CharacterSelect.selectGuid or CharacterSelect.undeleteGuid then
		for i = 1, numChars do
			local guid, _, _, _, _, forceRename = select(15, GetCharacterInfo(i));
			if guid == CharacterSelect.selectGuid or guid == CharacterSelect.undeleteGuid then
				CHARACTER_LIST_OFFSET = max(i - MAX_CHARACTERS_DISPLAYED, 0);
				CharacterSelect.selectedIndex = i;
				if guid == CharacterSelect.undeleteGuid then
                    CharacterSelect.undeleteSucceeded = true;
                    CharacterSelect.undeletePendingRename = forceRename;
				end
                    break;
                end
            end
		CharacterSelect.selectGuid = nil;
        CharacterSelect.undeleteGuid = nil;
    end

    local debugText = numChars..": ";
    local characterLimit = min(numChars, MAX_CHARACTERS_DISPLAYED);
    local areCharServicesShown = CharSelectServicesFlowFrame:IsShown();
    local isAccountLocked = CharacterSelect_IsAccountLocked();

    for i=1, characterLimit, 1 do
        local name, race, _, class, classFileName, classID, level, zone, sex, ghost, PCC, PRC, PFC, PRCDisabled, guid, _, _, _, boostInProgress, _, locked, isTrialBoost, isTrialBoostLocked, revokedCharacterUpgrade, _, lastLoginBuild, _, isExpansionTrialCharacter, _, _, _, _, _, _, isLockedFromOtherChars = GetCharacterInfo(GetCharIDFromIndex(i+CHARACTER_LIST_OFFSET));
        local productID, vasServiceState, vasServiceErrors, productInfo;
        if (guid) then
            productID, vasServiceState, vasServiceErrors = C_StoreGlue.GetVASPurchaseStateInfo(guid);
		end
        if (productID) then
            productInfo = C_StoreSecure.GetProductInfo(productID);
        end

        local button = _G["CharSelectCharacterButton"..i];
        button.isVeteranLocked = false;
        button.isAccountLocked = isAccountLocked;
		button.isWowTokenModeLocked = false;

        if (button.padlock) then
            CharacterSelect.characterPadlockPool:Release(button.padlock);
            button.padlock = nil;
        end

		local showlastLoginBuild = (IsGMClient()) and (not HideGMOnly());
		button.buttonText.LastVersion:SetShown(showlastLoginBuild);

        if ( name ) then
            local nameText = button.buttonText.name;
            local infoText = button.buttonText.Info;
            local locationText = button.buttonText.Location;
            local deathIcon = button.buttonText.graveIcon;
            local selfFoundButton = button.selfFoundButton;
			locationText:SetTextColor(GRAY_FONT_COLOR:GetRGB());

            if (not areCharServicesShown) then
                nameText:SetTextColor(1, .82, 0, 1);
            end

            if ( CharacterSelect.undeleting ) then
                nameText:SetFormattedText(CHARACTER_SELECT_NAME_DELETED, name);
            elseif ( locked or isLockedFromOtherChars or IsWowTokenLimitedModeEnabled() ) then
                nameText:SetText(name..CHARSELECT_CHAR_INACTIVE_CHAR);
            else
                nameText:SetText(name);
            end

			-- If we're not showing the build, don't bother doing nice formatting.
			if (showlastLoginBuild) then
				local currentVersion = select(7, GetBuildInfo());

				-- Set the Color based on the build being old / new
				if (lastLoginBuild < currentVersion) then
					button.buttonText.LastVersion:SetTextColor(YELLOW_FONT_COLOR:GetRGBA()) -- Earlier Build
				elseif (lastLoginBuild > currentVersion) then
					button.buttonText.LastVersion:SetTextColor(RED_FONT_COLOR:GetRGBA()) -- Later Build
				else
					button.buttonText.LastVersion:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGBA()) -- Current Build
				end

				button.buttonText.LastVersion:SetText(GenerateBuildString(lastLoginBuild));
			end

            if (isAccountLocked) then
                CharacterSelect_SetupPadlockForCharacterButton(button, guid);
                locationText:SetFontObject("GlueFontDisableSmall");
                locationText:SetText(zone);
                infoText:SetFormattedText(CHARACTER_SELECT_INFO, level, class);
            elseif (vasServiceState == Enum.VasPurchaseProgress.ApplyingLicense and #vasServiceErrors > 0) then
                infoText:SetText("|cffff2020"..VAS_ERROR_ERROR_HAS_OCCURRED.."|r");
                if (productInfo and productInfo.sharedData.name) then
                    locationText:SetText("|cffff2020"..productInfo.sharedData.name.."|r");
                else
                    locationText:SetText("");
                end
			elseif (vasServiceState == Enum.VasPurchaseProgress.WaitingOnQueue and not VAS_QUEUE_TIMES[guid]) then
				C_StoreGlue.RequestCharacterQueueTime(guid);
            elseif (vasServiceState == Enum.VasPurchaseProgress.ProcessingFactionChange) then
                infoText:SetText(CHARACTER_UPGRADE_PROCESSING);
                locationText:SetFontObject("GlueFontHighlightSmall");
                locationText:SetText(FACTION_CHANGE_CHARACTER_LIST_LABEL);
            elseif (boostInProgress) then
                infoText:SetText(CHARACTER_UPGRADE_PROCESSING);
                locationText:SetFontObject("GlueFontHighlightSmall");
                locationText:SetText(CHARACTER_UPGRADE_CHARACTER_LIST_LABEL);
            else
                if ( locked ) then
                    button.isVeteranLocked = true;
				end

				if ( IsWowTokenLimitedModeEnabled() ) then
					button.isWowTokenModeLocked = true;
                end

                locationText:SetFontObject("GlueFontDisableSmall");

                if isExpansionTrialCharacter then
					if IsExpansionTrial() then
						if isTrialBoostLocked then
							locationText:SetText(CHARACTER_SELECT_INFO_EXPANSION_TRIAL_BOOST_BUY_EXPANSION);
						else
							locationText:SetText(nil);
						end
					elseif CanUpgradeExpansion() then
						locationText:SetText(CHARACTER_SELECT_INFO_EXPANSION_TRIAL_BOOST_BUY_EXPANSION);
					else
						locationText:SetText(CHARACTER_SELECT_INFO_TRIAL_BOOST_APPLY_BOOST_TOKEN);
					end

                    if isTrialBoostLocked or not IsExpansionTrial() then
                        infoText:SetText(CHARACTER_SELECT_INFO_EXPANSION_TRIAL_BOOST_LOCKED);
                        CharacterSelect_SetupPadlockForCharacterButton(button, guid);

                        if (not areCharServicesShown) then
                            nameText:SetTextColor(.5, .5, .5, 1);
                        end
                    else
                        infoText:SetText(CHARACTER_SELECT_INFO_EXPANSION_TRIAL_PLAYABLE);
                    end
                elseif isTrialBoost then
                    locationText:SetText(CHARACTER_SELECT_INFO_TRIAL_BOOST_APPLY_BOOST_TOKEN);

                    if isTrialBoostLocked then
                        infoText:SetText(CHARACTER_SELECT_INFO_TRIAL_BOOST_LOCKED);
                        CharacterSelect_SetupPadlockForCharacterButton(button, guid);

                        if (not areCharServicesShown) then
                            nameText:SetTextColor(.5, .5, .5, 1);
                        end
                    else
                        infoText:SetText(CHARACTER_SELECT_INFO_TRIAL_BOOST_PLAYABLE);
                    end
                else
                    if( ghost ) then
                        infoText:SetFormattedText(CHARACTER_SELECT_INFO_GHOST, level, class);
                        if (C_GameRules.IsHardcoreActive() and deathIcon) then
                            deathIcon:Show();
                        end
                    else
                        infoText:SetFormattedText(CHARACTER_SELECT_INFO, level, class);
                        if (deathIcon) then
                            deathIcon:Hide();
                        end
                    end

                    if(selfFoundButton) then
                        selfFoundButton:SetShown((C_GameRules.IsSelfFoundAllowed() and IsCharacterSelfFound(GetCharIDFromIndex(i+CHARACTER_LIST_OFFSET))));
                    end

                    locationText:SetText(zone);

                    if revokedCharacterUpgrade then
                        CharacterSelect_SetupPadlockForCharacterButton(button, guid);
                    end
                end
            end
        end
        button:Show();
        button.index = i + CHARACTER_LIST_OFFSET;

        -- setup paid service button
        local paidServiceButton = _G["CharSelectPaidService"..i];
		paidServiceButton.VASIcon:SetSize(46, 46);
		paidServiceButton.tooltip = nil;
		paidServiceButton.tooltip2 = nil;
		paidServiceButton.tooltip3 = nil;
		paidServiceButton.disabledTooltip = nil;
		paidServiceButton.disabledTooltip2 = nil;
		paidServiceButton.disabledTooltip3 = nil;

        local upgradeIcon = _G["CharacterServicesProcessingIcon"..i];
        upgradeIcon:Hide();

        local serviceType, disableService;
        if (vasServiceState == Enum.VasPurchaseProgress.PaymentPending) then
            upgradeIcon:Show();
            upgradeIcon.tooltip = CHARACTER_UPGRADE_PROCESSING;
            upgradeIcon.tooltip2 = CHARACTER_STATE_ORDER_PROCESSING;
        elseif (vasServiceState == Enum.VasPurchaseProgress.ApplyingLicense and #vasServiceErrors > 0) then
            upgradeIcon:Show();
            local tooltip, desc;
            local info = StoreFrame_GetVASErrorMessage(guid, vasServiceErrors);
            if (info) then
                if (info.other) then
                    tooltip = VAS_ERROR_ERROR_HAS_OCCURRED;
                else
                    tooltip = VAS_ERROR_ADDRESS_THESE_ISSUES;
                end
                desc = info.desc;
            else
                tooltip = VAS_ERROR_ERROR_HAS_OCCURRED;
                desc = BLIZZARD_STORE_VAS_ERROR_OTHER;
            end
            upgradeIcon.tooltip = "|cffffd200" .. tooltip .. "|r";
            upgradeIcon.tooltip2 = "|cffff2020" .. desc .. "|r";
        elseif (boostInProgress) then
            upgradeIcon:Show();
            upgradeIcon.tooltip = CHARACTER_UPGRADE_PROCESSING;
            upgradeIcon.tooltip2 = CHARACTER_SERVICES_PLEASE_WAIT;
		elseif ( vasServiceState == Enum.VasPurchaseProgress.WaitingOnQueue ) then
			upgradeIcon:Show();
			upgradeIcon.tooltip = CHARACTER_UPGRADE_PROCESSING;
			if productInfo then
				upgradeIcon.tooltip2 = VAS_SERVICE_PROCESSING:format(productInfo.sharedData.name);
				if (VAS_QUEUE_TIMES[guid] and VAS_QUEUE_TIMES[guid] > 0) then
					upgradeIcon.tooltip2 = upgradeIcon.tooltip2 .. "|n" .. VAS_PROCESSING_ESTIMATED_TIME:format(SecondsToTime(VAS_QUEUE_TIMES[guid]*60, true, false, 2, true))
				end
			else
				upgradeIcon.tooltip2 = CHARACTER_SERVICES_PLEASE_WAIT;
			end
		elseif ( vasServiceState == Enum.VasPurchaseProgress.ProcessingFactionChange ) then
            upgradeIcon:Show();
            upgradeIcon.tooltip = CHARACTER_UPGRADE_PROCESSING;
            upgradeIcon.tooltip2 = CHARACTER_SERVICES_PLEASE_WAIT;
		elseif guid and IsCharacterVASLocked(guid) then
			CharacterSelect_SetupPadlockForCharacterButton(button, guid);
        elseif ( CharacterSelect.undeleting ) then
            paidServiceButton:Hide();
            paidServiceButton.serviceType = nil;
        elseif ( PFC ) then
            serviceType = PAID_FACTION_CHANGE;
            paidServiceButton.GoldBorder:Show();
            paidServiceButton.VASIcon:SetTexture("Interface\\Icons\\VAS_FactionChange");
            paidServiceButton.VASIcon:Show();
            paidServiceButton.texture:Hide();
            paidServiceButton.tooltip = PAID_FACTION_CHANGE_TOOLTIP;
            paidServiceButton.disabledTooltip = nil;
        elseif ( PRC ) then
            serviceType = PAID_RACE_CHANGE;
            paidServiceButton.GoldBorder:Show();
            paidServiceButton.VASIcon:SetTexture("Interface\\Icons\\VAS_RaceChange");
            paidServiceButton.VASIcon:Show();
            paidServiceButton.texture:Hide();
            disableService = PRCDisabled;
            paidServiceButton.tooltip = PAID_RACE_CHANGE_TOOLTIP;
            paidServiceButton.disabledTooltip = PAID_RACE_CHANGE_DISABLED_TOOLTIP;
        elseif ( PCC ) then
            serviceType = PAID_CHARACTER_CUSTOMIZATION;
            paidServiceButton.GoldBorder:Show();
            paidServiceButton.VASIcon:SetTexture("Interface\\Icons\\VAS_AppearanceChange");
            paidServiceButton.VASIcon:Show();
            paidServiceButton.texture:Hide();
            paidServiceButton.tooltip = PAID_CHARACTER_CUSTOMIZE_TOOLTIP;
            paidServiceButton.disabledTooltip = nil;
        end
        if ( serviceType ) then
            debugText = debugText.." "..(GetCharIDFromIndex(i+CHARACTER_LIST_OFFSET));
            paidServiceButton:Show();
            paidServiceButton.serviceType = serviceType;
            if ( disableService ) then
                paidServiceButton:Disable();
                paidServiceButton.texture:SetDesaturated(true);
                paidServiceButton.GoldBorder:SetDesaturated(true);
                paidServiceButton.VASIcon:SetDesaturated(true);
            elseif ( not paidServiceButton:IsEnabled() ) then
                paidServiceButton.texture:SetDesaturated(false);
                paidServiceButton.GoldBorder:SetDesaturated(false);
                paidServiceButton.VASIcon:SetDesaturated(false);
                paidServiceButton:Enable();
            end
        else
            paidServiceButton:Hide();
        end

        -- is a button being dragged?
        if ( CharacterSelect.draggedIndex ) then
            if ( CharacterSelect.draggedIndex == button.index ) then
                button:SetAlpha(1);
                button.buttonText.name:SetPoint("TOPLEFT", MOVING_TEXT_OFFSET, -5);
                button:LockHighlight();
                paidServiceButton.texture:SetVertexColor(1, 1, 1);
                paidServiceButton.GoldBorder:SetVertexColor(1, 1, 1);
                paidServiceButton.VASIcon:SetVertexColor(1, 1, 1);
            else
                button:SetAlpha(0.6);
                button.buttonText.name:SetPoint("TOPLEFT", DEFAULT_TEXT_OFFSET, -5);
                button:UnlockHighlight();
                paidServiceButton.texture:SetVertexColor(0.35, 0.35, 0.35);
                paidServiceButton.GoldBorder:SetVertexColor(0.35, 0.35, 0.35);
                paidServiceButton.VASIcon:SetVertexColor(0.35, 0.35, 0.35);
            end
        end
    end

    CharacterSelect_UpdateButtonState();

    CharacterSelect_UpdateStoreButton();

    CharacterSelect_ResetVeteranStatus();
    CharacterSelect_CheckVeteranStatus();

    CharacterSelect.createIndex = 0;

    local connected = IsConnectedToServer();
    if (CharSelectCreateCharacterButton:IsEnabled() and connected) then
        --If can create characters position and show the create button
        CharacterSelect.createIndex = numChars + 1;
        CharSelectCreateCharacterButton:SetID(CharacterSelect.createIndex);
        CharSelectCreateCharacterButton:SetDisabledTooltip(nil);
    end

    UpdateCharacterUndeleteStatus();

    if (MAX_CHARACTERS_DISPLAYED < CHARACTER_SELECT_MAX_CHARACTERS) then
        for i = MAX_CHARACTERS_DISPLAYED + 1, CHARACTER_SELECT_MAX_CHARACTERS, 1 do
            _G["CharSelectCharacterButton"..i]:Hide();
            _G["CharSelectPaidService"..i]:Hide();
            _G["CharacterServicesProcessingIcon"..i]:Hide();
        end
    end

    if (numChars < MAX_CHARACTERS_DISPLAYED) then
        for i = numChars + 1, MAX_CHARACTERS_DISPLAYED, 1 do
            _G["CharSelectCharacterButton"..i]:Hide();
            _G["CharSelectPaidService"..i]:Hide();
            _G["CharacterServicesProcessingIcon"..i]:Hide();
        end
    end

    if ( numChars == 0 and not skipSelect ) then
        CharacterSelect.selectedIndex = 0;
        CharacterSelect_SelectCharacter(CharacterSelect.selectedIndex, 1);
        return;
    end

    if ( numChars > MAX_CHARACTERS_DISPLAYED ) then
        CharSelectCreateCharacterButton:SetPoint("BOTTOM", -26, 15);
        CharSelectBackToActiveButton:SetPoint("BOTTOM", -8, 15);
        CharacterSelectCharacterFrame:SetWidth(280);
        CharacterSelectCharacterFrame.scrollBar:Show();
        CharacterSelectCharacterFrame.scrollBar:SetMinMaxValues(0, numChars - MAX_CHARACTERS_DISPLAYED);
        CharacterSelectCharacterFrame.scrollBar.blockUpdates = true;
        CharacterSelectCharacterFrame.scrollBar:SetValue(CHARACTER_LIST_OFFSET);
        CharacterSelectCharacterFrame.scrollBar.blockUpdates = nil;
    else
        CharSelectCreateCharacterButton:SetPoint("BOTTOM", -18, 10);
        CharSelectBackToActiveButton:SetPoint("BOTTOM", 0, 15);
        CharacterSelectCharacterFrame.scrollBar.blockUpdates = true;	-- keep mousewheel from doing anything
        CharacterSelectCharacterFrame:SetWidth(260);
        CharacterSelectCharacterFrame.scrollBar:Hide();
    end
	
	if not CharacterSelect.undeleting then
		if ( CharacterSelect_UseSpecialCreateButtons() ) then
			CreateCharacterButtonSpecial:Show();
			CharSelectUndeleteCharacterButtonSpecial:Show();
			CharSelectCreateCharacterButton:Hide();
			CharSelectUndeleteCharacterButton:Hide();
		else
			CreateCharacterButtonSpecial:Hide();
			CharSelectUndeleteCharacterButtonSpecial:Hide();
			CharSelectCreateCharacterButton:Show();
			CharSelectUndeleteCharacterButton:Show();
		end
	end

    if ( (CharacterSelect.selectedIndex == 0) or (CharacterSelect.selectedIndex > numChars) ) then
        CharacterSelect.selectedIndex = 1;
    end

    if ( not skipSelect ) then
        CharacterSelect_SelectCharacter(CharacterSelect.selectedIndex, 1);
    end
end


function CharacterSelectButton_OnClick(self)
    PlaySound(SOUNDKIT.GS_CHARACTER_CREATION_CLASS);
    local id = self:GetID() + CHARACTER_LIST_OFFSET;
    if ( id ~= CharacterSelect.selectedIndex ) then
        CharacterSelect_SelectCharacter(id);
    end
end

function CharacterSelectButton_OnDoubleClick(self)
    local id = self:GetID() + CHARACTER_LIST_OFFSET;
    if ( id ~= CharacterSelect.selectedIndex ) then
        CharacterSelect_SelectCharacter(id);
    end

    if (CharacterSelect_AllowedToEnterWorld()) then
        CharacterSelect_EnterWorld();
    end
end

function CharacterSelectButton_ShowMoveButtons(button)
    if (CharacterSelect.undeleting or isInBoostFlow() or CharacterSelect_IsAccountLocked()) then return end;
    local numCharacters = GetNumVisibleCharacters();
    if ( numCharacters <= 1 ) then
        return;
    end

	-- Since active characters are always sorted before inactive characters, we can use the active character count as an index.
	local lastActiveCharacterIndex = GetNumCharacters();

    if ( not CharacterSelect.draggedIndex ) then
        button.upButton:Show();
        button.upButton.normalTexture:SetPoint("CENTER", 0, 0);
        button.upButton.highlightTexture:SetPoint("CENTER", 0, 0);
        button.downButton:Show();
        button.downButton.normalTexture:SetPoint("CENTER", 0, 0);
        button.downButton.highlightTexture:SetPoint("CENTER", 0, 0);
        if ( button.index == 1 or button.index == lastActiveCharacterIndex+1 ) then
            button.upButton:Disable();
            button.upButton:SetAlpha(0.35);
        else
            button.upButton:Enable();
            button.upButton:SetAlpha(1);
        end

        if ( button.index == numCharacters or button.index == lastActiveCharacterIndex ) then
            button.downButton:Disable();
            button.downButton:SetAlpha(0.35);
        else
            button.downButton:Enable();
            button.downButton:SetAlpha(1);
        end
    end
end

function CharacterSelect_TabResize(self)
    local buttonMiddle = _G[self:GetName().."Middle"];
    local buttonMiddleDisabled = _G[self:GetName().."MiddleDisabled"];
    local width = self:GetTextWidth() - 8;
    local leftWidth = _G[self:GetName().."Left"]:GetWidth();
    buttonMiddle:SetWidth(width);
    buttonMiddleDisabled:SetWidth(width);
    self:SetWidth(width + (2 * leftWidth));
end

function CharacterSelect_CreateNewCharacter(characterType, allowCharacterTypeFrameToShow)
    if (CharacterSelect_IsAccountLocked()) then
        return;
    end

    C_CharacterCreation.SetCharacterCreateType(characterType);
    CharacterSelect_SelectCharacter(CharacterSelect.createIndex);
end

function CharacterSelect_SelectCharacter(index, noCreate)
    if ( index == CharacterSelect.createIndex ) then
        if ( not noCreate and not CharacterSelect_IsAccountLocked() ) then
            PlaySound(SOUNDKIT.GS_CHARACTER_SELECTION_CREATE_NEW);
            C_CharacterCreation.ClearCharacterTemplate();
            GlueParent_SetScreen("charcreate");
        end
    else
        local charID = GetCharIDFromIndex(index);
        SelectCharacter(charID);

        if (not C_WowTokenPublic.GetCurrentMarketPrice() or
            not CAN_BUY_RESULT_FOUND or (CAN_BUY_RESULT_FOUND ~= LE_TOKEN_RESULT_ERROR_SUCCESS and CAN_BUY_RESULT_FOUND ~= LE_TOKEN_RESULT_ERROR_SUCCESS_NO) ) then
            AccountReactivate_RecheckEligibility();
        end
        ReactivateAccountDialog_Open();
        SetBackgroundModel(CharacterSelectModel, GetSelectBackgroundModel(charID));

        -- Update the text of the EnterWorld button based on the type of character that's selected, default to "enter world"
        local text = ENTER_WORLD;
        local isTrialBoostLocked, revokedCharacterUpgrade = select(23,GetCharacterInfo(GetCharacterSelection()));
        if ( isTrialBoostLocked ) then
            text = ENTER_WORLD_UNLOCK_TRIAL_CHARACTER;
		elseif ( revokedCharacterUpgrade ) then
			text = ENTER_WORLD_UNLOCK_REVOKED_CHARACTER_UPGRADE;
        end
        CharSelectEnterWorldButton:SetText(text);
    end
end

function CharacterSelect_ForEachVisibleCharacterButton(func)
	local num = math.min(GetNumVisibleCharacters(), MAX_CHARACTERS_DISPLAYED);
	for i = 1, num do
		local button = _G["CharSelectCharacterButton"..i];
		func(button);
	end
end

function CharacterSelect_FindCharacterButtonByPredicate(predicate)
	local num = math.min(GetNumVisibleCharacters(), MAX_CHARACTERS_DISPLAYED);
	for i = 1, num do
		local button = _G["CharSelectCharacterButton"..i];
		if predicate(button) then
			return button;
		end
	end
	return nil;
end

function CharacterSelect_SelectCharacterByGUID(guid)
    local num = math.min(GetNumVisibleCharacters(), MAX_CHARACTERS_DISPLAYED);

    for i = 1, num do
        if (select(15, GetCharacterInfo(GetCharIDFromIndex(i + CHARACTER_LIST_OFFSET))) == guid) then
            local button = _G["CharSelectCharacterButton"..i];
            CharacterSelectButton_OnClick(button);
            button:LockHighlight();
			SetLastCharacterGuid(guid);
            UpdateCharacterSelection(CharacterSelect);
            CharacterSelect_GetCharacterListUpdate();
            return true;
        end
    end

    return false;
end

function CharacterDeleteDialog_OnShow()
    local name, race, _, class, classFileName, classID, level = GetCharacterInfo(GetCharIDFromIndex(CharacterSelect.selectedIndex));
    CharacterDeleteText1:SetFormattedText(CONFIRM_CHAR_DELETE, name, level, class);
    CharacterDeleteBackground:SetHeight(16 + CharacterDeleteText1:GetHeight() + CharacterDeleteText2:GetHeight() + 23 + CharacterDeleteEditBox:GetHeight() + 8 + CharacterDeleteButton1:GetHeight() + 16);
    CharacterDeleteButton1:Disable();
end

function CharacterSelect_EnterWorld()
    if (CharacterSelect_IsAccountLocked()) then
        return;
    end

    CharacterSelect_SaveCharacterOrder();
    local guid, _, _, _, _, _, locked = select(15,GetCharacterInfo(GetCharacterSelection()));

    if ( locked or IsWowTokenLimitedModeEnabled() ) then
        SubscriptionRequestDialog_Open();
        return;
    end

    PlaySound(SOUNDKIT.GS_CHARACTER_SELECTION_ENTER_WORLD);
    StopGlueAmbience();
    EnterWorld();
end

function CharacterSelect_Exit()
    CharacterSelect_SaveCharacterOrder();
    PlaySound(SOUNDKIT.GS_CHARACTER_SELECTION_EXIT);
    C_Login.DisconnectFromServer();
end

function CharacterSelect_AccountOptions()
    PlaySound(SOUNDKIT.GS_CHARACTER_SELECTION_ACCT_OPTIONS);
end

function CharacterSelect_TechSupport()
    PlaySound(SOUNDKIT.GS_CHARACTER_SELECTION_ACCT_OPTIONS);
    LaunchURL(TECH_SUPPORT_URL);
end

function CharacterSelect_Delete()
    if (CharacterSelect_IsAccountLocked()) then
        return;
    end

    PlaySound(SOUNDKIT.GS_CHARACTER_SELECTION_DEL_CHARACTER);
    if ( CharacterSelect.selectedIndex > 0 ) then
        CharacterSelect_SaveCharacterOrder();
        CharacterDeleteDialog:Show();
    end
end

function CharacterSelect_ChangeRealm()
    PlaySound(SOUNDKIT.GS_CHARACTER_SELECTION_DEL_CHARACTER);
    CharacterSelect_SaveCharacterOrder();
    CharacterSelect_SetAutoSwitchRealm(false);
    C_RealmList.RequestChangeRealmList();
end

function CharacterSelect_AllowedToEnterWorld()
    local isAccountLocked = CharacterSelect_IsAccountLocked();

    if (isAccountLocked) then
        return false;
    elseif (GetNumVisibleCharacters() == 0) then
        return false;
    elseif (CharacterSelect.undeleting) then
        return false;
    elseif (AccountReactivationInProgressDialog:IsShown()) then
        return false;
    elseif (GoldReactivateConfirmationDialog:IsShown()) then
        return false;
    elseif (TokenReactivateConfirmationDialog:IsShown()) then
        return false;
    elseif (CharSelectServicesFlowFrame:IsShown()) then
        return false;
	elseif (Kiosk.IsEnabled() and (CharacterSelect.hasPendingTrialBoost or KioskMode_IsWaitingOnTrial())) then
		return false;
	elseif (IsNameReservationOnly()) then
		return false;
    end

    local isTrialBoost, isTrialBoostLocked, revokedCharacterUpgrade, vasServiceInProgress, _, _, isExpansionTrialCharacter, _, _, _, _, _, _, isLockedFromOtherChars = select(22, GetCharacterInfo(GetCharacterSelection()));
	local trialBoostUnavailable = (isExpansionTrialCharacter and (isTrialBoostLocked or not IsExpansionTrial())) or (isTrialBoost and (isTrialBoostLocked or not C_CharacterServices.IsTrialBoostEnabled()));
    if (revokedCharacterUpgrade or trialBoostUnavailable or isLockedFromOtherChars) then
        return false;
    end

    --[[if (vasServiceInProgress) then
        return false;
    end]]

    return true;
end

function CharacterSelectRotateRight_OnUpdate(self)
    if ( self:GetButtonState() == "PUSHED" ) then
        SetCharacterSelectFacing(GetCharacterSelectFacing() + CHARACTER_FACING_INCREMENT);
    end
end

function CharacterSelectRotateLeft_OnUpdate(self)
    if ( self:GetButtonState() == "PUSHED" ) then
        SetCharacterSelectFacing(GetCharacterSelectFacing() - CHARACTER_FACING_INCREMENT);
    end
end

function CharacterSelect_ManageAccount()
    PlaySound(SOUNDKIT.GS_CHARACTER_SELECTION_ACCT_OPTIONS);
    LaunchURL(AUTH_NO_TIME_URL);
end

function CharacterSelect_PaidServiceOnClick(self, button, down, service)
    if (CharacterSelect_IsAccountLocked()) then
        return;
    end

    local translatedIndex =  GetCharIDFromIndex(self:GetID() + CHARACTER_LIST_OFFSET);
    if (translatedIndex <= 0 or translatedIndex > GetNumVisibleCharacters()) then
        -- Somehow our character order got borked, reset the offset and get an updated character list.
        CHARACTER_LIST_OFFSET = 0;
		CharacterCreateFrame:ClearPaidServiceInfo();
        CharacterSelect_GetCharacterListUpdate();
        return;
    end

	CharacterCreateFrame:SetPaidServiceInfo(service, translatedIndex);

    PlaySound(SOUNDKIT.GS_CHARACTER_SELECTION_CREATE_NEW);
    if (CharacterSelect.undeleting) then
        local guid = select(15, GetCharacterInfo(translatedIndex));
        CharacterSelect.pendingUndeleteGuid = guid;
        local timeStr = SecondsToTime(CHARACTER_UNDELETE_COOLDOWN, false, true, 1, false);
        GlueDialog_Show("UNDELETE_CONFIRM", UNDELETE_CONFIRMATION:format(timeStr));
	elseif (PAID_SERVICE_TYPE == PAID_CHARACTER_CLONE) then
		CloneConfirmation:Show();
    else
        GlueParent_SetScreen("charcreate");
    end
end

function CharacterSelect_StartCustomizeForVAS(vasType, info)
	CharacterCreateFrame:SetVASInfo(vasType, info);
	PlaySound(SOUNDKIT.GS_CHARACTER_SELECTION_CREATE_NEW);
	GlueParent_SetScreen("charcreate");
end

function CharacterSelectGoldPanelButton_DeathKnightSwap(self)
    local state;
    if ( not self:IsEnabled() ) then
        state = "disabled";
    elseif ( self.down ) then
        state = "down";
    else
        state = "up";
    end

    local deathKnightTag = "DEATHKNIGHT";
    local currentGlueTag = GetCurrentGlueTag();

    if ( self.currentGlueTag ~= currentGlueTag or self.state ~= state ) then
        self.currentGlueTag = currentGlueTag;
        self.state = state;

        if ( currentGlueTag == deathKnightTag ) then
            if (state == "disabled") then
                local textureBase = "Interface\\Buttons\\UI-DialogBox-goldbutton-disabled";

                self.Left:SetTexture(textureBase.."-left");
                self.Middle:SetTexture(textureBase.."-middle");
                self.Right:SetTexture(textureBase.."-right");
            else
                local textureBase = "UI-DialogBox-goldbutton-" .. state;

                self.Left:SetAtlas(textureBase.."-left-blue");
                self.Middle:SetAtlas(textureBase.."-middle-blue");
                self.Right:SetAtlas(textureBase.."-right-blue");
            end
            self:SetHighlightTexture("Interface\\Glues\\Common\\Glue-Panel-Button-Highlight-Blue");
        else
            local textureBase = "Interface\\Buttons\\UI-DialogBox-goldbutton-" .. state;

            self.Left:SetTexture(textureBase.."-left");
            self.Middle:SetTexture(textureBase.."-middle");
            self.Right:SetTexture(textureBase.."-right");
            self:SetHighlightTexture("Interface\\Glues\\Common\\Glue-Panel-Button-Highlight");
        end
    end
end

function CharacterSelectScrollDown_OnClick()
    PlaySound(SOUNDKIT.IG_INVENTORY_ROTATE_CHARACTER);
    local numChars = GetNumVisibleCharacters();
    if ( numChars > 1 ) then
        if ( CharacterSelect.selectedIndex < GetNumVisibleCharacters() ) then
            local newIndex = CharacterSelect.selectedIndex + 1;
            if (newIndex > MAX_CHARACTERS_DISPLAYED) then
                CHARACTER_LIST_OFFSET = newIndex - MAX_CHARACTERS_DISPLAYED;
            end
            CharacterSelect_SelectCharacter(newIndex);
        else
            CHARACTER_LIST_OFFSET = 0;
            CharacterSelect_SelectCharacter(1);
        end
        UpdateCharacterList();
        UpdateCharacterSelection(CharacterSelect);
    end
end

function CharacterSelectScrollUp_OnClick()
    PlaySound(SOUNDKIT.IG_INVENTORY_ROTATE_CHARACTER);
    local numChars = GetNumVisibleCharacters();
    if ( numChars > 1 ) then
        if ( CharacterSelect.selectedIndex > 1 ) then
            local newIndex = CharacterSelect.selectedIndex - 1;
            if (newIndex >= MAX_CHARACTERS_DISPLAYED) then
                CHARACTER_LIST_OFFSET = max(newIndex - MAX_CHARACTERS_DISPLAYED, 0);
            end
            CharacterSelect_SelectCharacter(newIndex);
        else
            CHARACTER_LIST_OFFSET = max(numChars - MAX_CHARACTERS_DISPLAYED, 0);
            CharacterSelect_SelectCharacter(numChars);
        end
        UpdateCharacterList();
        UpdateCharacterSelection(CharacterSelect);
    end
end

function CharacterSelectButton_OnDragUpdate(self)
    -- shouldn't be doing this without an index...
    if ( not CharacterSelect.draggedIndex) then
        CharacterSelectButton_OnDragStop(self);
        return;
    end
    -- only check Y-axis, user dragging horizontally should not change anything
    local _, cursorY = GetCursorPosition();
    if ( cursorY <= CHARACTER_LIST_TOP ) then
        -- check if the mouse is on a different button
        local buttonIndex = floor((CHARACTER_LIST_TOP - cursorY) / CHARACTER_BUTTON_HEIGHT) + 1;
        local button = _G["CharSelectCharacterButton"..buttonIndex];
        if ( button and button.index ~= CharacterSelect.draggedIndex and button:IsShown() ) then
            -- perform move
            if ( button.index > CharacterSelect.draggedIndex ) then
                -- move down
                MoveCharacter(CharacterSelect.draggedIndex, CharacterSelect.draggedIndex + 1, true);
            else
                -- move up
                MoveCharacter(CharacterSelect.draggedIndex, CharacterSelect.draggedIndex - 1, true);
            end
        end
    end
end

function CharacterSelectButton_OnDragStart(self)
    if ( GetNumVisibleCharacters() > 1 ) then
        CharacterSelect.pressDownButton = nil;
        CharacterSelect.draggedIndex = self:GetID() + CHARACTER_LIST_OFFSET;
        self:SetScript("OnUpdate", CharacterSelectButton_OnDragUpdate);
        for index = 1, MAX_CHARACTERS_DISPLAYED do
            local button = _G["CharSelectCharacterButton"..index];
            if ( button ~= self ) then
                button:SetAlpha(0.6);
                _G["CharSelectPaidService"..index].texture:SetVertexColor(0.35, 0.35, 0.35);
            end
        end
        self.buttonText.name:SetPoint("TOPLEFT", MOVING_TEXT_OFFSET, -5);
        self:LockHighlight();
        self.upButton:Hide();
        self.downButton:Hide();
    end
end

function CharacterSelectButton_OnDragStop(self)
    CharacterSelect.pressDownButton = nil;
    CharacterSelect.draggedIndex = nil;
    self:SetScript("OnUpdate", nil);
    for index = 1, MAX_CHARACTERS_DISPLAYED do
        local button = _G["CharSelectCharacterButton"..index];
        button:SetAlpha(1);
        button:UnlockHighlight();
        button.buttonText.name:SetPoint("TOPLEFT", DEFAULT_TEXT_OFFSET, -5);
        local paidBtn = _G["CharSelectPaidService"..index];
        paidBtn.texture:SetVertexColor(1, 1, 1);
        paidBtn.GoldBorder:SetVertexColor(1, 1, 1);
        paidBtn.VASIcon:SetVertexColor(1, 1, 1);
        if ( CharacterSelect.selectedIndex == index and button:IsMouseOver() ) then
			button:LockHighlight();
            CharacterSelectButton_ShowMoveButtons(button);
        end
    end
end

function MoveCharacter(originIndex, targetIndex, fromDrag)
    CharacterSelect.orderChanged = true;
    if ( targetIndex < 1 ) then
        targetIndex = #translationTable;
    elseif ( targetIndex > #translationTable ) then
        targetIndex = 1;
    end
    if ( originIndex == CharacterSelect.selectedIndex ) then
        CharacterSelect.selectedIndex = targetIndex;
    elseif ( targetIndex == CharacterSelect.selectedIndex ) then
        CharacterSelect.selectedIndex = originIndex;
    end
    translationTable[originIndex], translationTable[targetIndex] = translationTable[targetIndex], translationTable[originIndex];
    -- update character list
    if ( fromDrag ) then
        CharacterSelect.draggedIndex = targetIndex;
    end
    UpdateCharacterSelection(CharacterSelect);
    UpdateCharacterList();
end

function CharacterSelectButton_DisableDrag(button)
    button:SetScript("OnMouseDown", nil);
    button:SetScript("OnMouseUp", nil);
    button:SetScript("OnDragStart", nil);
    button:SetScript("OnDragStop", nil);
end

function CharacterSelectButton_EnableDrag(button)
    button:SetScript("OnDragStart", CharacterSelectButton_OnDragStart);
    button:SetScript("OnDragStop", CharacterSelectButton_OnDragStop);
    -- Functions here copied from CharacterSelect.xml
    button:SetScript("OnMouseDown", function(self)
        CharacterSelect.pressDownButton = self;
        CharacterSelect.pressDownTime = 0;
    end);
    button:SetScript("OnMouseUp", CharacterSelectButton_OnDragStop);
end

-- translation functions
function GetCharIDFromIndex(index)
    return translationTable[index] or 0;
end

function GetIndexFromCharID(charID)
    -- no need for lookup if the order hasn't changed
    if ( not CharacterSelect.orderChanged ) then
        return charID;
    end
    for index = 1, #translationTable do
        if ( translationTable[index] == charID ) then
            return index;
        end
    end
    return 0;
end

-- Server Alert Frame
function CharacterSelectServerAlert_OnLoad(self)
	ServerAlertMixin.OnLoad(self);
    self:RegisterEvent("LAUNCHER_LOGIN_STATUS_CHANGED");
    CharacterSelectServerAlert_UpdateEnabled();
end

function CharacterSelectServerAlert_OnEvent(self, event, ...)
    if ( event == "LAUNCHER_LOGIN_STATUS_CHANGED" ) then
        CharacterSelectServerAlert_UpdateEnabled();
    else
		ServerAlertMixin.OnEvent(self, event, ...);
    end
end

function CharacterSelectServerAlert_UpdateEnabled()
	local shouldSuppressServerAlert = C_Login.IsLauncherLogin() and not (AccountSaveFrame and AccountSaveFrame:IsShown());
	CharacterSelectServerAlertFrame:SetSuppressed(shouldSuppressServerAlert);
end

-- Account upgrade panel
function AccountUpgradePanel_GetDisplayExpansionLevel()
    if IsTrialAccount() then
		return nil, LE_EXPANSION_CLASSIC;
    end

	local currentExpansionLevel = GetClampedCurrentExpansionLevel();
	if IsExpansionTrial() then
		currentExpansionLevel = currentExpansionLevel - 1;
	end
	local upgradeExpansionLevel = math.min(currentExpansionLevel + 1, GetMaximumExpansionLevel());

	local minExpansionLevel = GetMinimumExpansionLevel();

	if currentExpansionLevel <= minExpansionLevel then
		currentExpansionLevel = LE_EXPANSION_CLASSIC;
	end

	if upgradeExpansionLevel <= minExpansionLevel then
		upgradeExpansionLevel = LE_EXPANSION_CLASSIC;
	end

	return currentExpansionLevel, upgradeExpansionLevel;
end

function AccountUpgradePanel_GetBannerInfo()
	local currentExpansionLevel = AccountUpgradePanel_GetDisplayExpansionLevel();
	local shouldShowBanner = IsWowTokenLimitedModeEnabled();
	return currentExpansionLevel, shouldShowBanner;
end

function AccountUpgradePanel_Update(isExpanded)
	local currentExpansionLevel, shouldShowBanner, upgradeButtonText, upgradeLogo, upgradeBanner, features = AccountUpgradePanel_GetBannerInfo();
    if ( shouldShowBanner ) then
		if (upgradeButtonText) then
			CharSelectAccountUpgradeButton:SetText(upgradeButtonText);
		end
        CharacterSelectServerAlertFrame:SetPoint("TOP", CharSelectAccountUpgradeMiniPanel, "BOTTOM", 0, -35);
        CharSelectAccountUpgradeButton:Show();
        if ( isExpanded ) then
            CharSelectAccountUpgradePanel:Show();
            CharSelectAccountUpgradeMiniPanel:Hide();

			CharSelectAccountUpgradePanel.logo:SetTexture(upgradeLogo);
            CharSelectAccountUpgradePanel.banner:SetAtlas(upgradeBanner, true);

            local featureFrames = CharSelectAccountUpgradePanel.featureFrames;
            for i=1, #features do
                local frame = featureFrames[i];
                if ( not frame ) then
                    frame = CreateFrame("FRAME", "CharSelectAccountUpgradePanelFeature"..i, CharSelectAccountUpgradePanel, "UpgradeFrameFeatureTemplate");
                    frame:SetPoint("TOPLEFT", featureFrames[i - 1], "BOTTOMLEFT", 0, 0);
                end

                frame.icon:SetTexture(features[i].icon);
                frame.text:SetText(features[i].text);
            end
            for i=#features + 1, #featureFrames do
                featureFrames[i]:Hide();
            end

            CharSelectAccountUpgradeButtonExpandCollapseButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up");
            CharSelectAccountUpgradeButtonExpandCollapseButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Down");
            CharSelectAccountUpgradeButtonExpandCollapseButton:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Disabled");
        else
            CharSelectAccountUpgradePanel:Hide();
            CharSelectAccountUpgradeMiniPanel:Hide();

            CharSelectAccountUpgradeButtonExpandCollapseButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up");
            CharSelectAccountUpgradeButtonExpandCollapseButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down");
            CharSelectAccountUpgradeButtonExpandCollapseButton:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled");
        end
	else
		CharSelectAccountUpgradePanel:Hide();
		CharSelectAccountUpgradeButton:Hide();
		CharSelectAccountUpgradeMiniPanel:Hide();
		CharacterSelectServerAlertFrame:SetPoint("TOP", CharacterSelectLogo, "BOTTOM", 0, -5);
    end
    CharSelectAccountUpgradeButton.isExpanded = isExpanded;
    SetCVar("expandUpgradePanel", isExpanded and "1" or "0");
end

function AccountUpgradePanel_ToggleExpandState()
    AccountUpgradePanel_Update(not CharSelectAccountUpgradeButton.isExpanded);
end

function AccountUpgradePanel_UpdateExpandState()
	-- Always hide these in Classic
    CharSelectAccountUpgradeButton.isExpanded = false;
    CharSelectAccountUpgradeButton.expandCollapseButton:Hide();
    AccountUpgradePanel_Update(CharSelectAccountUpgradeButton.isExpanded);
end

function CharSelectAccountUpgradeButton_OnClick(self)
    PlaySound(SOUNDKIT.GS_TITLE_OPTION_OK);
	if IsVeteranTrialAccount() then
		SubscriptionRequestDialog_Open();
	else
		UpgradeAccount();
	end
end

function CharacterSelect_ScrollList(self, value)
    if ( not self.blockUpdates ) then
        CHARACTER_LIST_OFFSET = floor(value);
        UpdateCharacterList(true);	-- skip selecting
        UpdateCharacterSelection(CharacterSelect);	-- for button selection
        if (CharSelectServicesFlowFrame:IsShown()) then
            CharacterServicesMaster_Restart();
        end
    end
end

function CharacterSelect_ScrollToCharacter(self, characterGUID)
	local numCharacters = GetNumVisibleCharacters();
	if numCharacters <= MAX_CHARACTERS_DISPLAYED then
		return;
	end

	local maxScroll = max(numCharacters - MAX_CHARACTERS_DISPLAYED, 0);
	for i = 1, maxScroll do
		local guid = select(15, GetCharacterInfo(i));
		if guid == characterGUID then
			CharacterSelect_ScrollList(self, i);
			return;
		end
	end

	CharacterSelect_ScrollList(self, maxScroll);
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

function CharacterSelect_SetScrollEnabled(enabled)
	if enabled then
		enableScroll(CharacterSelectCharacterFrame.scrollBar);
	else
		disableScroll(CharacterSelectCharacterFrame.scrollBar);
	end
end

function CharacterTemplatesFrame_Update()
    if IsGMClient() and HideGMOnly() then
        return;
    end

	local numTemplates = C_CharacterCreation.GetNumCharacterTemplates();
	local isShown = (numTemplates > 0) and IsConnectedToServer();
	CharacterTemplatesFrame:SetShown(isShown);
	CharacterTemplatesFrame.Dropdown:GenerateMenu();
end

function CharacterTemplatesFrame_OnLoad(self)
	self.Dropdown:SetWidth(180);
	self.characterIndex = 1;

	self.CreateTemplateButton:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.GS_CHARACTER_SELECTION_CREATE_NEW);
		C_CharacterCreation.SetCharacterTemplate(self.characterIndex);
		GlueParent_SetScreen("charcreate");
	end);
end

function CharacterTemplatesFrame_OnShow(self)
	local function IsSelected(characterIndex)
		return self.characterIndex == characterIndex;
	end

	local function SetSelected(characterIndex)
		self.characterIndex = characterIndex;
	end

	self.Dropdown:SetupMenu(function(dropdown, rootDescription)
		rootDescription:SetTag("MENU_CHARACTER_SELECT_TEMPLATE");
		
		for characterIndex = 1, C_CharacterCreation.GetNumCharacterTemplates() do
		    local name, description = C_CharacterCreation.GetCharacterTemplateInfo(characterIndex);
			local radio = rootDescription:CreateRadio(name, IsSelected, SetSelected, characterIndex);
			radio:SetTooltip(function(tooltip, elementDescription)
				GameTooltip_SetTitle(tooltip, name);
				GameTooltip_AddNormalLine(tooltip, description);
			end);
		end
	end);
end

function ToggleStoreUI()
	local wasShown = StoreFrame_IsShown();
    if ( not wasShown ) then
        --We weren't showing, now we are. We should hide all other panels.
        -- not sure if anything is needed here at the gluescreen
    end
    StoreFrame_SetShown(not wasShown);
end

function SetStoreUIShown(shown)
	local wasShown = StoreFrame_IsShown();
	if ( not wasShown and shown ) then
		--We weren't showing, now we are. We should hide all other panels.
		-- not sure if anything is needed here at the gluescreen
	end

	StoreFrame_SetShown(shown);
end

function PlayersOnServer_Update()
    if (IsGMClient() and HideGMOnly()) then
        return;
    end

    local self = PlayersOnServer;
    local connected = IsConnectedToServer();
    if (not connected) then
        self:Hide();
        return;
    end

    local showPlayers, numHorde, numAlliance = GetPlayersOnServer();
    if showPlayers then
        if not self:IsShown() then
            self:Show();
        end
        self.HordeCount:SetText(numHorde);
        self.AllianceCount:SetText(numAlliance);
        self.HordeStar:SetShown(numHorde < numAlliance);
        self.AllianceStar:SetShown(numAlliance < numHorde);
    else
        self:Hide();
    end
end

function CharacterSelect_ActivateFactionChange()
    if IsConnectedToServer() then
        EnableChangeFaction();
        CharacterSelect_GetCharacterListUpdate();
    end
end

function CharacterSelect_IsStoreAvailable()
    return C_StorePublic.IsEnabled() and not C_StorePublic.IsDisabledByParentalControls() and GetNumCharacters() > 0 and not CharacterSelect_IsAccountLocked();
end

function CharacterSelect_UpdateStoreButton()
	local enabled = CharacterSelect_IsStoreAvailable() and not Kiosk.IsEnabled();
	if CharacterSelectUI.useNavBar then
		StoreButton:Hide();
		CharacterSelectUI.VisibilityFramesContainer.NavBar:SetStoreButtonEnabled(enabled);
	else
		if enabled then
			StoreButton:Show();
		else
			StoreButton:Hide();
		end
	end
end

StaticPopupDialogs["TOKEN_GAME_TIME_OPTION_NOT_AVAILABLE"] = {
    text = ACCOUNT_REACTIVATE_OPTION_UNAVAILABLE,
    button1 = OKAY,
    escapeHides = true,
}

function CharacterSelect_HasVeteranEligibilityInfo()
    return TOKEN_COUNT_UPDATED and ((C_WowTokenGlue.GetTokenCount() > 0 or CAN_BUY_RESULT_FOUND) and C_WowTokenPublic.GetCurrentMarketPrice());
end

function CharacterSelect_ResetVeteranStatus()
    CAN_BUY_RESULT_FOUND = false;
    TOKEN_COUNT_UPDATED = false;
end

function CharacterSelect_CheckVeteranStatus()
    if (IsVeteranTrialAccount() and CharacterSelect_HasVeteranEligibilityInfo()) then
        ReactivateAccountDialog_Open();
    elseif (IsVeteranTrialAccount()) then
        if (not TOKEN_COUNT_UPDATED) then
            C_WowTokenPublic.UpdateTokenCount();
        end
        if (not CAN_BUY_RESULT_FOUND and TOKEN_COUNT_UPDATED) then
            C_WowTokenGlue.CheckVeteranTokenEligibility();
        end
        if (not C_WowTokenPublic.GetCurrentMarketPrice() and CAN_BUY_RESULT_FOUND) then
            C_WowTokenPublic.UpdateMarketPrice();
        end
    end
end

function CharacterSelect_UpdateButtonState()
    local hasCharacters = GetNumVisibleCharacters() > 0;
    local servicesEnabled = not CharSelectServicesFlowFrame:IsShown();
    local undeleting = CharacterSelect.undeleting;
    local undeleteEnabled, undeleteOnCooldown = GetCharacterUndeleteStatus();
    local redemptionInProgress = AccountReactivationInProgressDialog:IsShown() or GoldReactivateConfirmationDialog:IsShown() or TokenReactivateConfirmationDialog:IsShown();
    local inCompetitiveMode = IsCompetitiveModeEnabled();
	local inKioskMode = Kiosk.IsEnabled();
	local canCreateCharacter = CanCreateCharacter();
    local boostInProgress = select(19,GetCharacterInfo(GetCharacterSelection()));
    local isAccountLocked = CharacterSelect_IsAccountLocked();
	local isStoreAvailable = CharacterSelect_IsStoreAvailable();

    CharSelectEnterWorldButton:SetEnabled(CharacterSelect_AllowedToEnterWorld());
    CharacterSelectBackButton:SetEnabled(servicesEnabled and not undeleting and not boostInProgress);
	CharacterSelectUI.VisibilityToggleButton:SetEnabled(servicesEnabled and not undeleting and not redemptionInProgress);
    CharacterSelectDeleteButton:SetEnabled(hasCharacters and servicesEnabled and not undeleting and not redemptionInProgress and not CharacterSelect_IsRetrievingCharacterList() and not isAccountLocked);
    CharSelectChangeRealmButton:SetEnabled(servicesEnabled and not undeleting and not redemptionInProgress);
    CharSelectUndeleteCharacterButton:SetEnabled(canCreateCharacter and servicesEnabled and undeleteEnabled and not undeleteOnCooldown and not redemptionInProgress and not boostInProgress and not isAccountLocked);
    CharacterSelectAddonsButton:SetEnabled(servicesEnabled and not undeleting and not redemptionInProgress and not inKioskMode);
    CopyCharacterButton:SetEnabled(servicesEnabled and not undeleting and not redemptionInProgress and not isAccountLocked);
    ActivateFactionChange:SetEnabled(servicesEnabled and not undeleting and not redemptionInProgress and not isAccountLocked);
    ActivateFactionChange.texture:SetDesaturated(not (servicesEnabled and not undeleting and not redemptionInProgress and not isAccountLocked));
    CharacterTemplatesFrame.CreateTemplateButton:SetEnabled(servicesEnabled and not undeleting and not redemptionInProgress and not isAccountLocked);
    CharacterSelectMenuButton:SetEnabled(servicesEnabled and not redemptionInProgress);
    CharSelectCreateCharacterButton:SetEnabled(canCreateCharacter and servicesEnabled and not redemptionInProgress and not isAccountLocked and not IsWowTokenLimitedModeEnabled());
	if StoreButton then
		StoreButton:SetEnabled(servicesEnabled and not undeleting and not redemptionInProgress and not isAccountLocked and isStoreAvailable);
	end
	if CharacterSelectUI.VisibilityFramesContainer.NavBar then
		CharacterSelectUI.VisibilityFramesContainer.NavBar:SetStoreButtonEnabled(servicesEnabled and not undeleting and not redemptionInProgress and not isAccountLocked and isStoreAvailable);
	end

	if CharacterSelect.VASPools then
		for frame in CharacterSelect.VASPools:EnumerateActive() do
            frame:SetEnabled(not redemptionInProgress);
        end
    end

    if( CharacterSelect.CharacterBoosts ) then
        for _, frame in pairs(CharacterSelect.CharacterBoosts) do
            frame:SetEnabled(not redemptionInProgress and not isAccountLocked);
        end
    end

    CharSelectAccountUpgradeButton:SetEnabled(not redemptionInProgress and not undeleting and not inCompetitiveMode and not inKioskMode and not isAccountLocked);

    if isAccountLocked then
        CharSelectEnterWorldButton:SetDisabledTooltip(CHARACTER_SELECT_ACCOUNT_LOCKED);
        CharSelectCreateCharacterButton:SetDisabledTooltip(CHARACTER_SELECT_ACCOUNT_LOCKED);
        CharacterSelectDeleteButton:SetDisabledTooltip(CHARACTER_SELECT_ACCOUNT_LOCKED);
    else
        CharSelectEnterWorldButton:SetDisabledTooltip(nil);
        CharacterSelectDeleteButton:SetDisabledTooltip(nil);

        if GetNumVisibleCharacters() < GetNumCharacters() then
            -- If our number of visible characters is less than our total number of characters,
			-- display the Create Character button with a helpful error message.
            CharSelectCreateCharacterButton:SetDisabledTooltip(CHAR_CREATE_UNACTIVATED_CHARACTER_LIMIT);
		elseif IsWowTokenLimitedModeEnabled() then
			CharSelectCreateCharacterButton:SetDisabledTooltip(CHAR_CREATE_GAME_TIME_REQUIRED);
			CharSelectEnterWorldButton:SetDisabledTooltip(CHAR_ENTER_WORLD_GAME_TIME_REQUIRED);
        else
            CharSelectCreateCharacterButton:SetDisabledTooltip(nil);
        end
    end
    if (CharSelectReincarnateCharacterButton) then
		-- TEMP disable reincarnation during 1.15.2 release for CLASS-29127
		local disableReincarnation = true;
        local shouldShowReincarnate = C_GameRules.IsHardcoreActive() and not CharacterSelect.undeleting and not disableReincarnation;
        CharSelectReincarnateCharacterButton:SetShown(shouldShowReincarnate);
        CharSelectReincarnateCharacterButton:Enable(); -- Disabled when we are restoring a deleted character
    end
end

function CharacterSelect_DeleteCharacter(charID)
    if CharacterSelect_IsRetrievingCharacterList() or CharacterSelect_IsAccountLocked() then
        return;
    end

    DeleteCharacter(GetCharIDFromIndex(CharacterSelect.selectedIndex));
    CharacterDeleteDialog:Hide();
    PlaySound(SOUNDKIT.GS_TITLE_OPTION_OK);
    GlueDialog_Show("CHAR_DELETE_IN_PROGRESS");
end

function CharacterSelect_IsAccountLocked()
    return C_AccountServices.IsAccountLockedPostSave();
end

function CharacterSelect_ConditionallyLoadAccountSaveUI()
    if (C_AccountServices.IsAccountSaveEnabled()) then
        if (not ACCOUNT_SAVE_IS_LOADED) then
            ACCOUNT_SAVE_IS_LOADED = C_AddOns.LoadAddOn("Blizzard_AccountSaveUI");
        end
        if (AccountSaveFrame) then
            AccountSaveFrame:Show();

            if (GameRoomBillingFrame:IsShown()) then
				if StoreButton then
					GameRoomBillingFrame:SetPoint("TOPLEFT", StoreButton, "TOPRIGHT");
				else
					GameRoomBillingFrame:SetPoint("TOPLEFT", CharacterSelectAddonsButton, "TOPRIGHT");
				end
            end
        end
    elseif AccountSaveFrame then
        AccountSaveFrame:Hide();

        if (GameRoomBillingFrame:IsShown()) then
            GameRoomBillingFrame:SetPoint("TOP", CharacterSelectServerAlertFrame, "BOTTOM");
        end
    end
end

local KIOSK_AUTO_REALM_ADDRESS = nil
function SetKioskAutoRealmAddress(realmAddr)
	KIOSK_AUTO_REALM_ADDRESS = realmAddr;
end

function GetKioskAutoRealmAddress()
	return KIOSK_AUTO_REALM_ADDRESS;
end

function KioskMode_CheckAutoRealm()
    local realmAddr = GetKioskAutoRealmAddress();
    if (realmAddr) then
        CharacterSelect_SetAutoSwitchRealm(true);
		C_Login.RequestAutoRealmJoin(realmAddr);
        -- We only want to do this on first load
        SetKioskAutoRealmAddress(nil);
    end
end

local KIOSK_MODE_WAITING_ON_TRIAL = false;
function KioskMode_SetWaitingOnTrial(waiting)
    KIOSK_MODE_WAITING_ON_TRIAL = waiting;
end

function KioskMode_IsWaitingOnTrial()
    return KIOSK_MODE_WAITING_ON_TRIAL;
end

function KioskMode_CheckEnterWorld()
    if (not Kiosk.IsEnabled()) then
        return;
    end

	if (not KioskMode_IsWaitingOnTrial()) then
        if (KioskModeSplash:GetAutoEnterWorld()) then
            EnterWorld();
        else
			if (not IsGMClient()) then
            KioskDeleteAllCharacters();
			end
            if (IsKioskGlueEnabled()) then
                GlueParent_SetScreen("kioskmodesplash");
            end
        end
    end
end

local function GetCharacterServiceDisplayOrder()
	local displayOrder = C_CharacterServices.GetCharacterServiceDisplayInfo();
	table.sort(displayOrder, function(left, right)
		return left.priority < right.priority;
	end)

	return displayOrder;
end

-- CHARACTER BOOST (SERVICES)
function CharacterServicesMaster_UpdateServiceButton()
	if not CharacterSelect.VASPools then
		local vasResetter = function(framePool, frame)
            frame:Hide();
            frame.Glow:Hide();
            frame.GlowSpin:Hide();
            frame.GlowPulse:Hide();
            frame.GlowSpin.SpinAnim:Stop();
            frame.GlowPulse.PulseAnim:Stop();
			frame:ClearAllPoints();
			frame.layoutIndex = nil;
		end

		CharacterSelect.VASPools = CreateFramePoolCollection();
		CharacterSelect.VASPools:CreatePool("BUTTON", CharacterSelectUI.VisibilityFramesContainer.VASTokenContainer, "CharacterBoostTemplate", vasResetter);
		CharacterSelect.VASPools:CreatePool("BUTTON", CharacterSelectUI.VisibilityFramesContainer.VASTokenContainer, "CharacterVASTemplate", vasResetter);
	end

	CharacterSelect.VASPools:ReleaseAll();

    UpgradePopupFrame:Hide();
    CharacterSelectUI.VisibilityFramesContainer.WarningText:Hide();

    if CharacterSelect.undeleting or CharSelectServicesFlowFrame:IsShown() then
        return;
    end

	local displayOrder = GetCharacterServiceDisplayOrder();
    local upgradeInfo = C_SharedCharacterServices.GetUpgradeDistributions();
    local hasPurchasedBoost = false;
    for id, data in pairs(upgradeInfo) do
		hasPurchasedBoost = hasPurchasedBoost or data.hasPaid;
    end

	local isExpansionTrial, expansionTrialRemainingSeconds = GetExpansionTrialInfo();
	if isExpansionTrial then
		upgradeInfo[0] = {hasPaid = false, hasFree = true, amount = 1, isExpansionTrial = true, remainingTime = expansionTrialRemainingSeconds};
	end

    -- support refund notice for Korea
    if hasPurchasedBoost and C_StoreSecure.GetCurrencyID() == CURRENCY_KRW then
        CharacterSelectUI.VisibilityFramesContainer.WarningText:Show();
    end

	CharacterServicesMaster_UpdateVASButtons(displayOrder);
	CharacterServicesMaster_UpdateBoostButtons(displayOrder, upgradeInfo);
	CharacterSelectUI.VisibilityFramesContainer.VASTokenContainer:Layout();
end

function DisplayBattlepayTokens(upgradeInfo, boostType)
	if upgradeInfo and upgradeInfo.amount > 0 then
	local charUpgradeDisplayData = C_CharacterServices.GetCharacterServiceDisplayData(boostType);
		DisplayBattlepayTokenType(charUpgradeDisplayData, upgradeInfo);
	end
end

function DisplayBattlepayTokenType(charUpgradeDisplayData, upgradeInfo)
	if upgradeInfo.amount > 0 then
		CharacterSelect.numActiveCharacterBoosts = CharacterSelect.numActiveCharacterBoosts + 1;

		local boostFrameIndex = CharacterSelect.numActiveCharacterBoosts;
		local frame = CharacterSelect.CharacterBoosts[boostFrameIndex];
		if not frame then
			frame = CreateFrame("Button", "CharacterSelectCharacterBoost"..boostFrameIndex, CharacterSelect, "CharacterBoostTemplate");
		end

		frame.data = charUpgradeDisplayData;
		frame.data.isExpansionTrial = upgradeInfo.isExpansionTrial;
		frame.data.frameType = FRAME_TYPE_CHARACTER_BOOST;
		frame.hasFreeBoost = upgradeInfo.hasFree;
		frame.remainingTime = upgradeInfo.remainingTime;

        if charUpgradeDisplayData.icon then
		    SetPortraitToTexture(frame.Icon, charUpgradeDisplayData.icon);
		    SetPortraitToTexture(frame.Highlight.Icon, charUpgradeDisplayData.icon);
        end
		frame.Highlight.IconBorder:SetAtlas(charUpgradeDisplayData.iconBorderAtlas);

		if boostFrameIndex > 1 then
			frame:SetPoint("TOPRIGHT", CharacterSelect.CharacterBoosts[boostFrameIndex - 1], "TOPLEFT", -3, 0);
		else
			frame:SetPoint("TOPRIGHT", CharacterSelectCharacterFrame, "TOPLEFT", -18, -4);
		end

		if upgradeInfo.remainingTime then
			frame.Timer:StartTimer(upgradeInfo.remainingTime, 1, true);
		else
			frame.Timer:StopTimer();
		end

		if upgradeInfo.amount > 1 then
			frame.Ring:Show();
			frame.NumberBackground:Show();
			frame.Number:Show();
			frame.Number:SetText(upgradeInfo.amount);
		else
			frame.Ring:Hide();
			frame.NumberBackground:Hide();
			frame.Number:Hide();
		end

		if not C_CharacterServices.IsBoostEnabled() then
			frame:Disable();
			if ( frame.Icon ) then
				frame.Icon:SetDesaturated(true);
			end
			if ( frame.IconBorder ) then
				frame.IconBorder:SetDesaturated(true);
			end
			if ( frame.Highlight.Icon ) then
				frame.Highlight.Icon:SetDesaturated(true);
			end
			if ( frame.Highlight.IconBorder ) then
				frame.Highlight.IconBorder:SetDesaturated(true);
			end
			if ( frame.Ring ) then
				frame.Ring:SetDesaturated(true);
			end
			if ( frame.Number ) then
				frame.Number:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
			end
		else
			frame:Enable();
			if ( frame.Icon ) then
				frame.Icon:SetDesaturated(false);
			end
			if ( frame.IconBorder ) then
				frame.IconBorder:SetDesaturated(false);
			end
			if ( frame.Highlight.Icon ) then
				frame.Highlight.Icon:SetDesaturated(false);
			end
			if ( frame.Highlight.IconBorder ) then
				frame.Highlight.IconBorder:SetDesaturated(false);
			end
			if ( frame.Ring ) then
				frame.Ring:SetDesaturated(false);
			end
			if ( frame.Number ) then
				frame.Number:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
			end
		end

		frame:Show();
	end
end

------------------------------------------------------------------
-- API for VAS tokens:
------------------------------------------------------------------
local function GetVASDistributions()
	local distributions = C_CharacterServices.GetVASDistributions();
	local distributionsByVASType = {};

	for index, distribution in ipairs(distributions) do
		distribution.tokenStatus = distribution.inReview and "review" or "normal";
		distribution.isVAS = true;
		distributionsByVASType[distribution.serviceType] = distribution;
	end

	for vasType, distribution in pairs(distributionsByVASType) do
		if not IsVASEnabledOnRealm(vasType) then
			distribution.tokenStatus = "disabledOnRealm";
		else
			-- Are there any characters for which this token is valid?
			local usable = false;
			for i = 1, GetNumCharacters() do
				local charID = GetCharIDFromIndex(i);
				if vasType == Enum.ValueAddedServiceType.PaidCharacterTransfer then
					usable = DoesClientThinkTheCharacterIsEligibleForPCT(charID);
				elseif vasType == Enum.ValueAddedServiceType.PaidFactionChange then
					usable = DoesClientThinkTheCharacterIsEligibleForPFC(charID);
				elseif vasType == Enum.ValueAddedServiceType.PaidRaceChange then
					usable = DoesClientThinkTheCharacterIsEligibleForPRC(charID);
				elseif vasType == Enum.ValueAddedServiceType.PaidNameChange then
					usable = DoesClientThinkTheCharacterIsEligibleForPNC(charID);
				end
				if usable then
					break;
				end
			end
			if not usable then
				distribution.tokenStatus = "noCharacters";
			end
		end
	end

	return distributionsByVASType;
end

local function GetVASTokenStatus(vasTokenInfo)
	return vasTokenInfo.tokenStatus or "normal";
end

local function GetVASTokenAlpha(vasTokenInfo)
	return GetVASTokenStatus(vasTokenInfo) == "normal" and 1 or .7;
end

local statusToTooltipLookup = {
	review = VAS_TOKEN_TOOLTIP_STATUS_REVIEW,
	noCharacters = VAS_TOKEN_TOOLTIP_STATUS_NO_CHARACTERS,
	disabledOnRealm = VAS_TOKEN_TOOLTIP_STATUS_DISABLED_ON_REALM,
};

local function GetVASTokenStatusTooltip(vasTokenInfo)
	-- nil is fine, it means no tooltip.
	return statusToTooltipLookup[GetVASTokenStatus(vasTokenInfo)];
end

local function IsVASTokenUsable(vasTokenInfo)
	return GetVASTokenStatus(vasTokenInfo) == "normal";
end

local function AddVASButton(charUpgradeDisplayData, upgradeInfo, template)
	local frame = CharacterSelect.VASPools:Acquire(template);
	frame.layoutIndex = CharacterSelect.VASPools:GetNumActive();

	frame.data = charUpgradeDisplayData;
	frame.upgradeInfo = upgradeInfo;
	frame.data.isExpansionTrial = upgradeInfo.isExpansionTrial;
	frame.data.isVAS = upgradeInfo.isVAS;
	frame.hasFreeBoost = upgradeInfo.hasFree;
	frame.remainingTime = upgradeInfo.remainingTime;

    if charUpgradeDisplayData.icon then
	    SetPortraitToTexture(frame.Icon, charUpgradeDisplayData.icon);
	    SetPortraitToTexture(frame.Highlight.Icon, charUpgradeDisplayData.icon);
    end
	frame.Highlight.IconBorder:SetAtlas(charUpgradeDisplayData.iconBorderAtlas);

	frame:SetAlpha(GetVASTokenAlpha(upgradeInfo));

	if upgradeInfo.remainingTime then
		frame.Timer:StartTimer(upgradeInfo.remainingTime, 1, true);
	else
		frame.Timer:StopTimer();
	end

	if upgradeInfo.amount > 1 then
		frame.Ring:Show();
		frame.NumberBackground:Show();
		frame.Number:Show();
		frame.Number:SetText(upgradeInfo.amount);
	else
		frame.Ring:Hide();
		frame.NumberBackground:Hide();
		frame.Number:Hide();
	end

	frame:Show();
end

function CharacterServicesMaster_UpdateBoostButtons(displayOrder, upgradeInfo)
	for _, characterService in pairs(displayOrder) do
		if not characterService.isVAS then
			local boostType = characterService.serviceID;
			local boostUpgradeInfo = upgradeInfo[boostType];
			if boostUpgradeInfo and boostUpgradeInfo.amount > 0 then
				local charUpgradeDisplayData = C_CharacterServices.GetCharacterServiceDisplayData(boostType);
				AddVASButton(charUpgradeDisplayData, boostUpgradeInfo, "CharacterBoostTemplate");
			end
		end
	end
end

function CharacterServicesMaster_UpdateVASButtons(displayOrder)
	local upgradeInfo = GetVASDistributions();
	for _, characterService in pairs(displayOrder) do
		if characterService.isVAS then
			local vasType = characterService.serviceID;
			local vasInfo = upgradeInfo[vasType];
			if vasInfo and vasInfo.amount > 0 then
				local vasDisplay = C_CharacterServices.GetCharacterServiceDisplayDataByVASType(vasType);
				if vasDisplay then
					AddVASButton(vasDisplay, vasInfo, "CharacterVASTemplate");
				end
			end
		end
	end
end

local textureKitRegionInfo = {
	["Top"] = {formatString= "%s-boostpopup-top", useAtlasSize=true},
	["Middle"] = {formatString="%s-boostpopup-middle", useAtlasSize = false},
	["Bottom"] = {formatString="%s-boostpopup-bottom", useAtlasSize = true},
	["CloseButtonBG"] = {formatString="%s-boostpopup-exit-frame", useAtlasSize = true}
}

function DisplayBattlepayTokenFreeFrame(freeFrame)
	local freeFrameData = freeFrame.data;
	if not freeFrame.data.isExpansionTrial then
	freeFrame.Glow:SetPoint("CENTER", freeFrame.IconBorder, "CENTER");
	freeFrame.Glow:Show();
	freeFrame.GlowSpin.SpinAnim:Play();
	freeFrame.GlowPulse.PulseAnim:Play();
	freeFrame.GlowSpin:Show();
	freeFrame.GlowPulse:Show();
	end

	local popupData = freeFrameData.popupInfo;
	if popupData then
		local popupFrame = UpgradePopupFrame;

		popupFrame.data = freeFrameData;
		popupFrame.Title:SetText(popupData.title);

		local timerHeight = 0;
		if freeFrame.remainingTime then
			popupFrame.Timer:StartTimer(freeFrame.remainingTime, 1, true, true, BOOST_POPUP_TIMER_FORMAT_STRING);
			popupFrame.Description:SetPoint("TOP", popupFrame.Timer, "BOTTOM", 0, -20);
			timerHeight = popupFrame.Timer:GetHeight() + 2;
		else
			popupFrame.Timer:StopTimer();
			popupFrame.Description:SetPoint("TOP", popupFrame.Title, "BOTTOM", 0, -20);
		end

		popupFrame.Description:SetText(popupData.description);
		popupFrame:SetupTextureKit(popupData.textureKitPrefix, textureKitRegionInfo);

		local baseHeight;
		if freeFrame.data.isExpansionTrial then
			popupFrame.GetStartedButton:SetText(EXPANSION_TRIAL_CREATE_TRIAL_CHARACTER);
			popupFrame.LaterButton:Hide();
			baseHeight = 160;
		else
			popupFrame.GetStartedButton:SetText(CHARACTER_UPGRADE_POPUP_BOOST_EXISTING_CHARACTER);
			popupFrame.LaterButton:Show();
			baseHeight = 180;
		end

		popupFrame:SetHeight(baseHeight + timerHeight + popupFrame.Description:GetHeight() + popupFrame.Title:GetHeight());
		popupFrame:Show();
	end
end

local function CharacterUpgradePopup_CheckSetPopupSeen(data)
    if UpgradePopupFrame and UpgradePopupFrame.data and UpgradePopupFrame:IsVisible() then
        if data.expansion == UpgradePopupFrame.data.expansion then
			if UpgradePopupFrame.data.isExpansionTrial and C_SharedCharacterServices.GetLastSeenExpansionTrialPopup() < data.expansion then
				C_SharedCharacterServices.SetExpansionTrialPopupSeen(data.expansion);
			elseif C_SharedCharacterServices.GetLastSeenCharacterUpgradePopup() < data.expansion then
				C_SharedCharacterServices.SetCharacterUpgradePopupSeen(data.expansion);
			end
        end
    end
end

local function HandleUpgradePopupButtonClick(self)
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    local data = self:GetParent().data;
    CharacterUpgradePopup_CheckSetPopupSeen(data);
    return data;
end

UpgradePopupFrameMixin = CreateFromMixins(BaseExpandableDialogMixin);

function UpgradePopupFrameMixin:OnCloseClick()
	PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE);
	CharacterUpgradePopup_CheckSetPopupSeen(self.data);
	CharacterServicesMaster_UpdateServiceButton();
end

function CharacterUpgradePopup_OnCharacterBoostDelivered(boostType, guid, reason)
    if reason == "forUnrevokeBoost" then
		local flowData = C_CharacterServices.GetCharacterServiceDisplayData(boostType);
		CharacterUpgradePopup_BeginCharacterUpgradeFlow(flowData, guid);
    else
        local flowData = C_CharacterServices.GetCharacterServiceDisplayData(boostType);

        if reason == "forClassTrialUnlock" then
            CharacterUpgradePopup_BeginCharacterUpgradeFlow(flowData, guid);
        else
            CharacterUpgradePopup_BeginCharacterUpgradeFlow(flowData);
        end
    end
end

local function BeginFlow(flow, data)
    CharSelectServicesFlowFrame:Show();
	flow:SetTarget(data); -- NOTE: It seems like data can be changed in the middle of a flow, so keeping this here until that is determined.
	CharacterServicesMaster_SetFlow(CharacterServicesMaster, flow);
end

function CharacterUpgradePopup_BeginCharacterUpgradeFlow(data, guid)
	CharacterUpgradeFlow:SetTrialBoostGuid(nil);

	if guid then
		local isTrialBoost, isTrialBoostLocked, revokedCharacterUpgrade = select(22, GetCharacterInfoByGUID(guid));
		if isTrialBoost then
			CharacterUpgradeFlow:SetTrialBoostGuid(guid);
		else
			CharacterUpgradeFlow:SetAutoSelectGuid(guid);
		end
	end

	CharacterUpgradePopup_CheckSetPopupSeen(data);
	BeginFlow(CharacterUpgradeFlow, data);
end

function CharacterUpgradePopup_BeginVASFlow(data, guid)
	assert(data.vasType ~= nil);
	if data.vasType == Enum.ValueAddedServiceType.PaidCharacterTransfer then
		BeginFlow(PaidCharacterTransferFlow, data);
	elseif data.vasType == Enum.ValueAddedServiceType.PaidFactionChange then
		BeginFlow(PaidFactionChangeFlow, data);
	elseif data.vasType == Enum.ValueAddedServiceType.PaidRaceChange then
		BeginFlow(PaidRaceChangeFlow, data);
	elseif data.vasType == Enum.ValueAddedServiceType.PaidNameChange and PaidNameChangeFlowClassic then
		BeginFlow(PaidNameChangeFlowClassic, data);
	else
		error("Unsupported VAS Type Flow");
	end
end

function CharacterUpgradePopup_OnStartClick(self)
    local data = HandleUpgradePopupButtonClick(self);
	if data.isExpansionTrial then
		CharacterSelect_CreateNewCharacter(Enum.CharacterCreateType.TrialBoost, true);
	else
    CharacterUpgradePopup_BeginCharacterUpgradeFlow(data);
	end
end

function CharacterUpgradePopup_OnStartEnter(self)
	local data = self:GetParent().data;
	if not data.isExpansionTrial then
		GlueTooltip:SetOwner(self, "ANCHOR_RIGHT");
		local tooltip = CHARACTER_UPGRADE_POPUP_BOOST_EXISTING_CHARACTER_TOOLTIP:format(data.flowTitle);
		GlueTooltip:SetText(tooltip, nil, nil, nil, nil, true);
	end
end

function CharacterUpgradePopup_OnStartLeave(self)
	GlueTooltip:Hide();
end

function CharacterUpgradePopup_OnTryNewClick(self)
    HandleUpgradePopupButtonClick(self);

    if (C_CharacterServices.IsTrialBoostEnabled()) then
        CharacterUpgrade_BeginNewCharacterCreation(Enum.CharacterCreateType.TrialBoost);
    end
end

CharacterVASMixin = {};

function CharacterVASMixin:OnClick()
	if IsWowTokenLimitedModeEnabled() then
        GlueDialog_Show("CHARACTER_BOOST_FEATURE_RESTRICTED", CHARACTER_BOOST_YOU_MUST_REACTIVATE);
	elseif IsVASTokenUsable(self.upgradeInfo) then
		CharacterUpgradePopup_BeginVASFlow(self.data);
	end
end

function CharacterVASMixin:OnEnter()
	self.Highlight:Show();

	local tooltip = GetAppropriateTooltip();
	tooltip:SetOwner(self, "ANCHOR_LEFT");

	if self.data.isExpansionTrial or self.data.isVAS then
		GameTooltip_SetTitle(tooltip, self.data.popupInfo.title);
		GameTooltip_AddNormalLine(tooltip, self.data.popupInfo.description);

		local statusLine = GetVASTokenStatusTooltip(self.upgradeInfo);
		if statusLine then
			GameTooltip_AddErrorLine(tooltip, statusLine);
		end
	else
		GameTooltip_SetTitle(tooltip, self.data.flowTitle);
		GameTooltip_AddNormalLine(tooltip, BOOST_TOKEN_TOOLTIP_DESCRIPTION:format(self.data.level));
	end

    tooltip:Show();
end

function CharacterVASMixin:OnLeave()
    self.Highlight:Hide();
	GetAppropriateTooltip():Hide();
end

function CharacterServicesTokenBoost_OnClick(self)
	if not C_CharacterServices.IsBoostEnabled() then
		return;
	elseif self.data.isExpansionTrial then
		if UpgradePopupFrame:IsShown() then
			UpgradePopupFrame:Hide();
		else
			DisplayBattlepayTokenFreeFrame(self);
		end
    elseif IsVeteranTrialAccount() or IsWowTokenLimitedModeEnabled() then
        GlueDialog_Show("CHARACTER_BOOST_FEATURE_RESTRICTED", CHARACTER_BOOST_YOU_MUST_REACTIVATE);
    elseif IsTrialAccount() then
        GlueDialog_Show("CHARACTER_BOOST_FEATURE_RESTRICTED", CHARACTER_BOOST_YOU_MUST_UPGRADE);
    elseif C_CharacterCreation.HasSufficientExperienceForAdvancedCreation() then
        CharacterUpgradePopup_BeginCharacterUpgradeFlow(self.data);
    else
        GlueDialog_Show("CHARACTER_BOOST_NO_CHARACTERS_WARNING", nil, self.data);
    end
end

CharacterBoostMixin = {};

function CharacterBoostMixin:OnClick()
	if self.data.isExpansionTrial then
		if UpgradePopupFrame:IsShown() then
			UpgradePopupFrame:Hide();
		else
			DisplayBattlepayTokenFreeFrame(self);
		end
    elseif IsVeteranTrialAccount() then
        GlueDialog_Show("CHARACTER_BOOST_FEATURE_RESTRICTED", CHARACTER_BOOST_YOU_MUST_REACTIVATE);
    elseif IsTrialAccount() then
        GlueDialog_Show("CHARACTER_BOOST_FEATURE_RESTRICTED", CHARACTER_BOOST_YOU_MUST_UPGRADE);
    else
        CharacterUpgradePopup_BeginCharacterUpgradeFlow(self.data);
	end
end

GameLogoDarkBackdropMixin = {};

function GameLogoDarkBackdropMixin:OnLoad()
	self:RegisterEvent("GAME_MODE_DISPLAY_INFO_UPDATED");
	self:Update();
end

function GameLogoDarkBackdropMixin:OnEvent(event)
	if event == "GAME_MODE_DISPLAY_INFO_UPDATED" then
		self:Update();
	end
end

function GameLogoDarkBackdropMixin:Update()
	local gameModeDisplayInfo = C_GameRules.GetCurrentGameModeDisplayInfo();
	if gameModeDisplayInfo then
		if gameModeDisplayInfo.logoUsesDarkBackdrop then
			self.BackdropTexture:Show();
			return;
		end
	end

	self.BackdropTexture:Hide();
end

function CharacterServicesMaster_OnLoad(self)
    self.flows = {};

    self:RegisterEvent("PRODUCT_DISTRIBUTIONS_UPDATED");
    self:RegisterEvent("UPDATE_EXPANSION_LEVEL");
    self:RegisterEvent("PRODUCT_ASSIGN_TO_TARGET_FAILED");
end

local completedGuid;

function CharacterServicesMaster_OnEvent(self, event, ...)
    if (event == "PRODUCT_DISTRIBUTIONS_UPDATED" or event == "UPDATE_EXPANSION_LEVEL") then
        CharacterServicesMaster_UpdateServiceButton();
    elseif (event == "PRODUCT_ASSIGN_TO_TARGET_FAILED") then
        if (CharacterServicesMaster.pendingGuid and C_CharacterServices.DoesGUIDHavePendingFactionChange(CharacterServicesMaster.pendingGuid)) then
            CharacterServicesMaster.pendingGuid = nil;
            GlueDialog_Show("BOOST_FACTION_CHANGE_IN_PROGRESS");
            return;
        end
        GlueDialog_Show("PRODUCT_ASSIGN_TO_TARGET_FAILED");
    end
end

function CharacterServicesMaster_OnCharacterListUpdate()
	CharacterServicesMaster_UpdateServiceButton();

    CharacterServicesMaster.pendingGuid = nil;
    local automaticBoostType = C_CharacterServices.GetAutomaticBoost();
	local startAutomatically = automaticBoostType ~= nil;
    if (CharacterServicesMaster.waitingForLevelUp) then
        C_CharacterServices.ApplyLevelUp();
        CharacterServicesMaster.waitingForLevelUp = false;
        KioskMode_SetWaitingOnTrial(false);
        KioskMode_CheckEnterWorld();
    elseif (CharacterUpgrade_IsCreatedCharacterUpgrade() or startAutomatically) then
		if (C_CharacterServices.GetAutomaticBoostCharacter()) then
			local automaticBoostCharacterGUID = C_CharacterServices.GetAutomaticBoostCharacter();
			CharacterSelect_ScrollToCharacter(CharacterSelect, automaticBoostCharacterGUID);
			CharacterUpgradePopup_BeginCharacterUpgradeFlow(C_CharacterServices.GetCharacterServiceDisplayData(automaticBoostType), automaticBoostCharacterGUID);
			CharacterSelect_SelectCharacterByGUID(automaticBoostCharacterGUID);
        else
			if (CharacterUpgrade_IsCreatedCharacterUpgrade()) then
				CharacterUpgradeFlow:SetTarget(CHARACTER_UPGRADE_CREATE_CHARACTER_DATA);
			else
				CharacterUpgradeFlow:SetTarget(C_CharacterServices.GetCharacterServiceDisplayData(automaticBoostType), false);
			end

			if CharacterUpgradeFlow.data then
				CharSelectServicesFlowFrame:Show();
				CharacterUpgradeFlow:SetTarget(CharacterUpgradeFlow.data);
				CharacterServicesMaster_SetFlow(CharacterServicesMaster, CharacterUpgradeFlow);
			end

			CharacterUpgrade_ResetBoostData();
		end

        C_CharacterServices.SetAutomaticBoost(nil);
		C_CharacterServices.SetAutomaticBoostCharacter(nil);
    elseif (C_CharacterServices.HasQueuedUpgrade()) then
        local guid = C_CharacterServices.GetQueuedUpgradeGUID();

          CharacterServicesMaster.waitingForLevelUp = CharacterSelect_SelectCharacterByGUID(guid);

        C_CharacterServices.ClearQueuedUpgrade();
    end
end

function CharacterServicesMaster_UpdateFinishLabel(self)
    local finishButton = self:GetParent().FinishButton;
    local displayText = self.flow:GetFinishLabel();
    finishButton:SetText(displayText);
end

function CharacterServicesMaster_SetFlow(self, flow)
    self.flow = flow;
	self.flows[flow] = true;
	CharacterServicesMaster_HideFlows(self);

    flow:Initialize(self);

    if flow.data.icon then
        SetPortraitToTexture(self:GetParent().Icon, flow.data.icon);
    end
    self:GetParent().TitleText:SetText(flow.data.flowTitle);

    CharacterServicesMaster_UpdateFinishLabel(self);

    for i = 1, #flow.Steps do
        local block = flow.Steps[i];
        if (not block.HiddenStep) then
            block.frame:SetFrameLevel(CharacterServicesMaster:GetFrameLevel()+2);
            block.frame:SetParent(self);
        end
    end
end

function CharacterServicesMaster_SetCurrentBlock(self, block, wasFromRewind)
    local parent = self:GetParent();
    if (not block.HiddenStep) then
        CharacterServicesMaster_SetBlockActiveState(block);
    end
    self.currentBlock = block;
    self.blockComplete = false;
    parent.BackButton:SetShown(block.Back);
    parent.NextButton:SetShown(block.Next);
    parent.FinishButton:SetShown(block.Finish);
    if (block.Finish) then
        self.FinishTime = GetTime();
    end

    -- Some blocks may remember user choices when the user returns to
    -- them.  As such, even though the block isn't finished for purposes
    -- of advancing to the next step, the next button should still be
    -- enabled.  This addresses an issue where the "alert, next is ready!"
    -- animation was playing even though from the user's point of view
    -- the next button never really appeared disabled.

    local isFinished = block:IsFinished(wasFromRewind);

    if wasFromRewind then
        local forwardStateWouldBeFinished = block:IsFinished();
        parent.NextButton:SetEnabled(forwardStateWouldBeFinished);
    else
        parent.NextButton:SetEnabled(isFinished);
    end

    -- Since there's no way to finish the entire flow and then go back,
    -- the finishButton is always enabled based on the block actually
    -- being finished.
    parent.FinishButton:SetEnabled(isFinished);
end

function CharacterServicesMaster_Restart()
    local self = CharacterServicesMaster;

    if (self.flow) then
        self.flow:Restart(self);
    end
end

function CharacterServicesMaster_Update()
    local self = CharacterServicesMaster;
    local parent = self:GetParent();
    local block = self.currentBlock;

    CharacterServicesMaster_UpdateFinishLabel(self);

	if (block and block:IsFinished()) then

        if (not block.HiddenStep and (block.AutoAdvance or self.blockComplete)) then
            CharacterServicesMaster_SetBlockFinishedState(block);
        end

		if (block.AutoAdvance) then
			if ( block.Popup and ( not block.ShouldShowPopup or block:ShouldShowPopup() )) then
		 		local text;
				if ( block.GetPopupText ) then
					text = block:GetPopupText();
				end
				GlueDialog_Show(block.Popup, text);
				return;
			end
            self.flow:Advance(self);
        else
            if (block.Next) then
                if (not parent.NextButton:IsEnabled()) then
                    parent.NextButton:SetEnabled(true);
                    if ( parent.NextButton:IsVisible() ) then
                        parent.NextButton.Flash:Show();
                        parent.NextButton.PulseAnim:Play();
                    end
                end
            elseif (block.Finish) then
                parent.FinishButton:SetEnabled(true);
            end
        end
    elseif (block) then
        if (block.Next) then
            parent.NextButton:SetEnabled(false);

            if ( parent.NextButton:IsVisible() ) then
                parent.NextButton.PulseAnim:Stop();
                parent.NextButton.Flash:Hide();
            end
        elseif (block.Finish) then
            parent.FinishButton:SetEnabled(false);
        end
    end
    self.currentTime = 0;

	self.flow:CheckRewind(self);
end

function CharacterServicesMaster_OnHide(self)
    for flow, _ in pairs(self.flows) do
        flow:OnHide();
    end
end

function CharacterServicesMaster_HideFlows(self)
	for flow in pairs(self.flows) do
		flow:HideBlocks();
	end
end

function CharacterServicesMaster_SetBlockActiveState(block)
    block.frame.StepLabel:Show();
    block.frame.StepNumber:Show();
    block.frame.StepActiveLabel:Show();
    block.frame.StepActiveLabel:SetText(block.ActiveLabel);
    block.frame.ControlsFrame:Show();
    block.frame.Checkmark:Hide();
    block.frame.StepFinishedLabel:Hide();
    block.frame.ResultsLabel:Hide();
end

function CharacterServicesMaster_SetBlockFinishedState(block)
    block.frame.Checkmark:Show();
    block.frame.StepFinishedLabel:Show();
    block.frame.StepFinishedLabel:SetText(block.ResultsLabel);
    block.frame.ResultsLabel:Show();
    if (block.FormatResult) then
        block.frame.ResultsLabel:SetText(block:FormatResult());
    else
        block.frame.ResultsLabel:SetText(block:GetResult());
    end
    block.frame.StepLabel:Hide();
    block.frame.StepNumber:Hide();
    block.frame.StepActiveLabel:Hide();
    block.frame.ControlsFrame:Hide();
end

function CharacterServicesMasterBackButton_OnClick()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    local master = CharacterServicesMaster;
    master.flow:Rewind(master);
end

function CharacterServicesMasterNextButton_OnClick()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    local master = CharacterServicesMaster;
    if ( master.currentBlock.Popup and
        ( not master.currentBlock.ShouldShowPopup or master.currentBlock:ShouldShowPopup() )) then
        local text;
        if ( master.currentBlock.GetPopupText ) then
            text = master.currentBlock:GetPopupText();
        end
        GlueDialog_Show(master.currentBlock.Popup, text);
        return;
    end

    CharacterServicesMaster_Advance();
end

function CharacterServicesProcessingIcon_OnEnter(self)
    GlueTooltip:SetOwner(self, "ANCHOR_LEFT", -20, 0);
    GlueTooltip:AddLine(self.tooltip, 1.0, 1.0, 1.0);
    GlueTooltip:AddLine(self.tooltip2, nil, nil, nil, 1, 1);
    GlueTooltip:Show();
end

function CharacterServicesMaster_Advance()
    local master = CharacterServicesMaster;
    master.blockComplete = true;
    CharacterServicesMaster_Update();
    master.flow:Advance(master);
end

function CharacterServicesMasterFinishButton_OnClick(self)
	if CharacterServicesMaster.flow:ShouldFinishBehaveLikeNext() then
		CharacterServicesMasterNextButton_OnClick();
		return;
	end

    -- wait a bit after button is shown so no one accidentally upgrades the wrong character
    if ( GetTime() - CharacterServicesMaster.FinishTime < 0.5 ) then
        return;
    end
    local master = CharacterServicesMaster;
    local parent = master:GetParent();
    local success = master.flow:Finish(master);
    if (success) then
        PlaySound(SOUNDKIT.GS_CHARACTER_SELECTION_CREATE_NEW);
        parent:Hide();
    else
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    end
end

function CharacterUpgradeSecondChanceWarningFrameConfirmButton_OnClick(self)
    CharacterUpgradeSecondChanceWarningFrame.warningAccepted = true;

    CharacterUpgradeSecondChanceWarningFrame:Hide();

    CharacterServicesMasterFinishButton_OnClick(CharacterServicesMasterFinishButton);
end

function CharacterUpgradeSecondChanceWarningFrameCancelButton_OnClick(self)
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);

    CharacterUpgradeSecondChanceWarningFrame:Hide();

    CharacterUpgradeSecondChanceWarningFrame.warningAccepted = false;
end

function CharacterUpgradeSecondChanceWarningFrameConfirmButton_OnShow(self)
	self.hideTimer = 0;
end

BOOST_BUTTON_DELAY = 2;
function CharacterUpgradeSecondChanceWarningFrameConfirmButton_Update(self, elapsed)
	GlueParent_DeathKnightButtonSwap(self);

	if(self.hideTimer == nil) then self.hideTimer = 0 end;
	self.hideTimer = math.min(self.hideTimer + elapsed, BOOST_BUTTON_DELAY);
	if(self.hideTimer >= BOOST_BUTTON_DELAY and not CharacterUpgradeSecondChanceWarningBackground.ConfirmButton:IsEnabled()) then
		CharacterUpgradeSecondChanceWarningBackground.ConfirmButton:Enable();
	end
end

function CharacterUpgradeMaxLevelWarningFrameConfirmButton_OnClick(self)
    CharacterUpgradeMaxLevelWarningFrame.warningAccepted = true;
    CharacterUpgradeMaxLevelWarningFrame:Hide();
    CharacterServicesMasterFinishButton_OnClick(CharacterServicesMasterFinishButton);
end

function CharacterUpgradeMaxLevelWarningFrameCancelButton_OnClick(self)
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    CharacterUpgradeMaxLevelWarningFrame:Hide();
    CharacterUpgradeMaxLevelWarningFrame.warningAccepted = false;
end

function CharacterUpgradeMaxLevelWarningFrameConfirmButton_OnShow(self)
	self.hideTimer = 0;
end

function CharacterUpgradeMaxLevelWarningFrameConfirmButton_Update(self, elapsed)
	GlueParent_DeathKnightButtonSwap(self);

	if(self.hideTimer == nil) then self.hideTimer = 0 end;
	self.hideTimer = math.min(self.hideTimer + elapsed, BOOST_BUTTON_DELAY);
	if(self.hideTimer >= BOOST_BUTTON_DELAY and not CharacterUpgradeMaxLevelWarningBackground.ConfirmButton:IsEnabled()) then
		CharacterUpgradeMaxLevelWarningBackground.ConfirmButton:Enable();
	end
end

-- CHARACTER UNDELETE

StaticPopupDialogs["UNDELETE_FAILED"] = {
    text = UNDELETE_FAILED_ERROR,
    button1 = OKAY,
    escapeHides = true,
}

StaticPopupDialogs["UNDELETE_NAME_TAKEN"] = {
    text = UNDELETE_NAME_TAKEN,
    button1 = OKAY,
    escapeHides = true,
}

StaticPopupDialogs["UNDELETE_DEATHKNIGHT_LEVEL_REQUIREMENT"] = {
	text = UNDELETE_DEATHKNIGHT_LEVEL_REQUIREMENT,
	button1 = OKAY,
	escapeHides = true,
}

StaticPopupDialogs["UNDELETE_NO_CHARACTERS"] = {
    text = UNDELETE_NO_CHARACTERS;
    button1 = OKAY,
    button2 = nil,
}

StaticPopupDialogs["UNDELETE_FAILED_PVP"] = {
	text = CHAR_CREATE_PVP_TEAMS_VIOLATION,
	button1 = OKAY,
	escapeHides = true,
}
StaticPopupDialogs["UNDELETE_SUCCEEDED"] = {
    text = UNDELETE_SUCCESS,
    button1 = OKAY,
    escapeHides = true,
}

StaticPopupDialogs["UNDELETE_SUCCEEDED_NAME_TAKEN"] = {
    text = UNDELETE_SUCCESS_NAME_CHANGE_REQUIRED,
    button1 = OKAY,
    escapeHides = true,
}

StaticPopupDialogs["UNDELETE_CONFIRM"] = {
    text = UNDELETE_CONFIRMATION,
    button1 = OKAY,
    button2 = CANCEL,
    OnAccept = function ()
        CharacterSelect_FinishUndelete(CharacterSelect.pendingUndeleteGuid);
        CharacterSelect.pendingUndeleteGuid = nil;
    end,
    OnCancel = function ()
        CharacterSelect.pendingUndeleteGuid = nil;
    end,
}

function CharacterSelect_StartCharacterUndelete()
    CharacterSelect.undeleting = true;
    CharacterSelect.undeleteChanged = true;

	CharacterSelectUI.VisibilityToggleButton:Hide();
    CharSelectCreateCharacterButton:Hide();
    CreateCharacterButtonSpecial:Hide();
    CharSelectUndeleteCharacterButton:Hide();
    CharSelectUndeleteCharacterButtonSpecial:Hide();
    CharSelectChangeRealmButton:Hide();
    CharSelectUndeleteLabel:Show();

	if CharacterSelect_UseSpecialCreateButtons() then
		CharSelectBackToActiveButtonSpecial:Show();
		CharSelectBackToActiveButton:Hide();
	else
		CharSelectBackToActiveButtonSpecial:Hide();
		CharSelectBackToActiveButton:Show();
	end

    if (CharSelectReincarnateCharacterButton) then
        CharSelectReincarnateCharacterButton:SetShown(false);
    end

    AccountReactivate_CloseDialogs();

    CharacterServicesMaster_UpdateServiceButton();
    StartCharacterUndelete();
end

function CharacterSelect_EndCharacterUndelete()
    CharacterSelect.undeleting = false;
    CharacterSelect.undeleteChanged = true;

	CharacterSelectUI.VisibilityToggleButton:Show();
    CharSelectBackToActiveButton:Hide();
	CharSelectBackToActiveButtonSpecial:Hide();
    CharSelectChangeRealmButton:Show();
    CharSelectUndeleteLabel:Hide();

    if (CharSelectReincarnateCharacterButton) then
        local shouldShowReincarnate = C_GameRules.IsHardcoreActive();
        CharSelectReincarnateCharacterButton:SetShown(shouldShowReincarnate);
    end

    CharacterServicesMaster_UpdateServiceButton();
    EndCharacterUndelete();
end

function CharacterSelect_FinishUndelete(guid)
    GlueDialog_Show("UNDELETING_CHARACTER");

    UndeleteCharacter(guid);
    CharacterSelect.createIndex = 0;
end

function UpdateCharacterUndeleteButton(button)
	local enabled, onCooldown, cooldown, remaining = GetCharacterUndeleteStatus();
	local canCreateCharacter = CanCreateCharacter();
	local charactersAreHidden = GetNumVisibleCharacters() < GetNumCharacters();
    local isAccountLocked = CharacterSelect_IsAccountLocked();

	CHARACTER_UNDELETE_COOLDOWN = cooldown;
	CHARACTER_UNDELETE_COOLDOWN_REMAINING = remaining;

	button:SetEnabled(enabled and not onCooldown and canCreateCharacter and not isInBoostFlow() and not isAccountLocked);
	if (isInBoostFlow()) then
		button.tooltip = nil;
	elseif (not enabled) then
		button.tooltip = UNDELETE_TOOLTIP_DISABLED;
	elseif (onCooldown) then
		local timeStr = SecondsToTime(remaining, false, true, 1, false);
		button:SetTooltipInfo(nil);
		button:SetDisabledTooltip(UNDELETE_TOOLTIP_COOLDOWN:format(timeStr));
	elseif (not canCreateCharacter and charactersAreHidden) then
		button:SetTooltipInfo(nil);
		button:SetDisabledTooltip(CHAR_CREATE_UNACTIVATED_CHARACTER_LIMIT);
	else
		button:SetTooltipInfo(nil, UNDELETE_TOOLTIP);
		button:SetDisabledTooltip(nil);
	end
end

function UpdateCharacterUndeleteStatus()
	UpdateCharacterUndeleteButton(CharSelectUndeleteCharacterButton);
	UpdateCharacterUndeleteButton(CharSelectUndeleteCharacterButtonSpecial);
end

-- COPY CHARACTER

MAX_COPY_CHARACTER_BUTTONS = 19;
COPY_CHARACTER_BUTTON_HEIGHT = 16;

StaticPopupDialogs["COPY_CHARACTER"] = {
    text = "",
    button1 = OKAY,
    button2 = CANCEL,
    escapeHides = true,
    OnAccept = function ()
        CopyCharacterFromLive();
    end,
}

StaticPopupDialogs["COPY_ACCOUNT_DATA"] = {
    text = COPY_ACCOUNT_CONFIRM,
    button1 = OKAY,
    button2 = CANCEL,
    escapeHides = true,
    OnAccept = function ()
        CopyCharacter_AccountDataFromLive();
    end,
}

StaticPopupDialogs["COPY_IN_PROGRESS"] = {
    text = COPY_IN_PROGRESS,
    button1 = nil,
    button2 = nil,
    ignoreKeys = true,
    spinner = true,
}

StaticPopupDialogs["UNDELETING_CHARACTER"] = {
    text = RESTORING_CHARACTER_IN_PROGRESS,
    ignoreKeys = true,
    spinner = true,
}

function CopyCharacterFromLive()
    if ( not IsGMClient() ) then
		CopyAccountCharacterFromLive(CopyCharacterFrame_GetSelectedRegionID(), CopyCharacterFrame.SelectedIndex);
	else
		CopyAccountCharacterFromLive(CopyCharacterFrame_GetSelectedRegionID(), CopyCharacterFrame.SelectedIndex, CopyCharacterFrame.RealmName:GetText(), CopyCharacterFrame.CharacterName:GetText());
	end
    GlueDialog_Show("COPY_IN_PROGRESS");
end

function CopyCharacter_AccountDataFromLive()
    if ( not IsGMClient() ) then
        CopyAccountDataFromLive(CopyCharacterFrame_GetSelectedRegionID());
    else
        CopyAccountDataFromLive(CopyCharacterFrame_GetSelectedRegionID(), CopyCharacterFrame.RealmName:GetText(), CopyCharacterFrame.CharacterName:GetText());
    end
    GlueDialog_Show("COPY_IN_PROGRESS");
end

function CopyCharacterButton_OnLoad(self)
	CopyCharacterButton_UpdateButtonState();
end

function CopyCharacterButton_OnClick(self)
    CopyCharacterFrame:SetShown( not CopyCharacterFrame:IsShown() );
end

function CopyCharacterButton_UpdateButtonState()
	CopyCharacterButton:SetShown(C_CharacterServices.IsLiveRegionCharacterListEnabled() or C_CharacterServices.IsLiveRegionCharacterCopyEnabled() or C_CharacterServices.IsLiveRegionAccountCopyEnabled());
end

function CopyCharacterSearch_OnClick(self)
    ClearAccountCharacters();
    CopyCharacterFrame_Update(CopyCharacterFrame.scrollFrame);
    RequestAccountCharacters(CopyCharacterFrame_GetSelectedRegionID(), CopyCharacterFrame.RealmName:GetText(), CopyCharacterFrame.CharacterName:GetText());
    self:Disable();
end

function CopyCharacterCopy_OnClick(self)
    if ( not GlueDialog:IsShown() ) then
		if ( CopyCharacterFrame.SelectedIndex ) then
			local name, realm = GetAccountCharacterInfo(CopyCharacterFrame.SelectedIndex);
			GlueDialog_Show("COPY_CHARACTER", format(COPY_CHARACTER_CONFIRM, name, realm));
		elseif ( IsGMClient() ) then
			GlueDialog_Show("COPY_CHARACTER", format(COPY_CHARACTER_CONFIRM, CopyCharacterFrame.CharacterName:GetText(), CopyCharacterFrame.RealmName:GetText()));
		end
    end
end

function CopyAccountData_OnClick(self)
    if ( not GlueDialog:IsShown() ) then
        GlueDialog_Show("COPY_ACCOUNT_DATA");
    end
end

function CopyCharacterEntry_OnClick(self)
    if ( CopyCharacterFrame.SelectedButton ) then
        CopyCharacterFrame.SelectedButton:UnlockHighlight();
        if ( not CopyCharacterFrame.SelectedButton.mouseOver ) then
            CopyCharacterEntry_Unhighlight( CopyCharacterFrame.SelectedButton );
        end
    end

    self:LockHighlight();
    CopyCharacterFrame.SelectedButton = self;
    CopyCharacterFrame.SelectedIndex = self:GetID() + FauxScrollFrame_GetOffset(CopyCharacterFrame.scrollFrame);
    CopyCharacterFrame.CopyButton:SetEnabled(C_CharacterServices.IsLiveRegionCharacterCopyEnabled());
end

function CopyCharacterEntry_Highlight(self)
    self.Name:SetFontObject("GameFontHighlight");
    self.Server:SetFontObject("GameFontHighlight");
    self.Class:SetFontObject("GameFontHighlight");
    self.Level:SetFontObject("GameFontHighlight");
end

function CopyCharacterEntry_OnEnter(self)
    CopyCharacterEntry_Highlight(self);
    self.mouseOver = true;
end

function CopyCharacterEntry_Unhighlight(self)
    self.Name:SetFontObject("GameFontNormalSmall");
    self.Server:SetFontObject("GameFontNormalSmall");
    self.Class:SetFontObject("GameFontNormalSmall");
    self.Level:SetFontObject("GameFontNormalSmall");
end

function CopyCharacterEntry_OnLeave(self)
    if ( CopyCharacterFrame.SelectedButton ~= self) then
        CopyCharacterEntry_Unhighlight(self);
    end
    self.mouseOver = false;
end

function CopyCharacterFrame_OnLoad(self)
    FauxScrollFrame_SetOffset(self.scrollFrame, 0);
    self.scrollFrame.ScrollBar.scrollStep = COPY_CHARACTER_BUTTON_HEIGHT;
    ButtonFrameTemplate_HidePortrait(self);
    self:RegisterEvent("ACCOUNT_CHARACTER_LIST_RECIEVED");
    self:RegisterEvent("CHAR_RESTORE_COMPLETE");
    self:RegisterEvent("ACCOUNT_DATA_RESTORED");
    for i=2, MAX_COPY_CHARACTER_BUTTONS do
        local newButton = CreateFrame("BUTTON", nil, CopyCharacterFrame, "CopyCharacterEntryTemplate");
        newButton:SetPoint("TOP", self.CharacterEntries[i-1], "BOTTOM", 0, -4);
        newButton:SetID(i);
        self.CharacterEntries[i] = newButton;
    end
end

function CopyCharacterFrame_OnShow(self)
    if ( self.SelectedButton ) then
        self.SelectedButton:UnlockHighlight();
        CopyCharacterEntry_Unhighlight(self.SelectedButton);
    end

	self.CopyButton:SetEnabled(false);

	local regions = C_CharacterServices.GetLiveRegionCharacterCopySourceRegions();
	self.selectedRegion = regions[1];
	
	local function IsSelected(regionID)
		return self.selectedRegion == regionID;
	end

	local function SetSelected(regionID)
		self.selectedRegion = regionID;

		if not IsGMClient() then
			RequestAccountCharacters(regionID);
		end
	end

	self.RegionID:SetWidth(100);
	self.RegionID:SetupMenu(function(dropdown, rootDescription)
		rootDescription:SetTag("MENU_CHARACTER_SELECT_REGION");

		for index, regionID in ipairs(regions) do
			local regionName = characterCopyRegions[regionID];
			if regionName then
				rootDescription:CreateRadio(regionName, IsSelected, SetSelected, regionID);
			end
		end
	end);

    self.SelectedButton = nil;
    self.SelectedIndex = nil;

    ClearAccountCharacters();
    CopyCharacterFrame_Update(self.scrollFrame);

    if ( not IsGMClient() ) then
        self.RealmName:Hide();
        self.CharacterName:Hide();
        self.SearchButton:Hide();
        RequestAccountCharacters(CopyCharacterFrame_GetSelectedRegionID());
    else
        self.RealmName:Show();
        self.RealmName:SetFocus();
        self.CharacterName:Show();
        self.SearchButton:Show();
		self.SearchButton:SetEnabled(C_CharacterServices.IsLiveRegionCharacterListEnabled());
	    self.CopyButton:SetEnabled(C_CharacterServices.IsLiveRegionCharacterCopyEnabled());
    end
	self.CopyAccountData:SetEnabled(C_CharacterServices.IsLiveRegionAccountCopyEnabled());
end

function CopyCharacterFrame_OnEvent(self, event, ...)
    if ( event == "ACCOUNT_CHARACTER_LIST_RECIEVED" ) then
        CopyCharacterFrame_Update(self.scrollFrame);
        self.SearchButton:Enable();
    elseif ( event == "CHAR_RESTORE_COMPLETE" or event == "ACCOUNT_DATA_RESTORED") then
        local success, token = ...;
        GlueDialog_Hide();
        self:Hide();
        if (not success) then
            GlueDialog_Show("OKAY", COPY_FAILED);
        end
    end
end

function CopyCharacterFrame_Update(self)
    local offset = FauxScrollFrame_GetOffset(self) or 0;
    local count = GetNumAccountCharacters();
    -- turn off the selected button, we'll see if it moved
    if (CopyCharacterFrame.SelectedButton) then
        CopyCharacterFrame.SelectedButton:UnlockHighlight();
        if (not CopyCharacterFrame.SelectedButton.mouseOver) then
            CopyCharacterEntry_Unhighlight(CopyCharacterFrame.SelectedButton);
        end
    end

    for i=1, MAX_COPY_CHARACTER_BUTTONS do
        local characterIndex = offset + i;
        local button = CopyCharacterFrame.CharacterEntries[i];
        if ( characterIndex <= count ) then
            local name, realm, class, level = GetAccountCharacterInfo(characterIndex);
            button.Name:SetText(name);
            button.Server:SetText(realm);
            button.Class:SetText(class);
            button.Level:SetText(level);
            -- The list moved, so we need to shuffle the selected button
            if ( CopyCharacterFrame.SelectedIndex == characterIndex ) then
                button:LockHighlight();
                CopyCharacterEntry_Highlight(button);
                CopyCharacterFrame.SelectedButton = button;
            end
            button:Enable();
            button:Show();
        else
            button:Disable();
            button:Hide();
        end
    end
    FauxScrollFrame_Update(CopyCharacterFrameScrollFrame, count, MAX_COPY_CHARACTER_BUTTONS, COPY_CHARACTER_BUTTON_HEIGHT );
end

function CopyCharacterScrollFrame_OnVerticalScroll(self, offset)
    FauxScrollFrame_OnVerticalScroll(self, offset, COPY_CHARACTER_BUTTON_HEIGHT, CopyCharacterFrame_Update)
end

function CopyCharacterFrame_GetSelectedRegionID()
	return CopyCharacterFrame.selectedRegion;
end

function CopyCharacterEditBox_OnLoad(self)
    self.parent = self:GetParent();
end

function CopyCharacterEditBox_OnShow(self)
    self:SetText("");
end

function CopyCharacterEditBox_OnEnterPressed(self)
    self:GetParent().SearchButton:Click();
end

function CopyCharacterRealmNameEditBox_OnTabPressed(self)
    self:GetParent().CharacterName:SetFocus();
end

function CopyCharacterCharacterNameEditBox_OnTabPressed(self)
    self:GetParent().RealmName:SetFocus();
end

function CharacterSelect_ShowStoreFrameForBoostType(boostType, guid, reason)
	if not StoreFrame_IsShown or not StoreFrame_IsShown() then
		ToggleStoreUI();
	end

	StoreFrame_SelectBoost(boostType, reason, guid);
end

function CharacterSelect_CheckApplyBoostToUnlockTrialCharacter(guid)
    local availableBoostTypes = GetAvailableBoostTypesForCharacterByGUID(guid);
    if #availableBoostTypes >= 1 then
		-- We should only ever get in this case if #availableBoostTypes == 1. If there is more than 1 available
		-- boost type then users use a dropdown to choose a boost.
        local flowData = C_CharacterServices.GetCharacterServiceDisplayData(availableBoostTypes[1]);
        CharacterUpgradePopup_BeginCharacterUpgradeFlow(flowData, guid);
    else
	    local purchasableBoostType = C_CharacterServices.GetActiveCharacterUpgradeBoostType();
        CharacterSelect_ShowStoreFrameForBoostType(purchasableBoostType, guid, "forClassTrialUnlock");
    end
end

function CharacterSelect_CheckApplyBoostToUnrevokeBoost(guid)
    local hasBoost, boostType = C_CharacterServices.HasRequiredBoostForUnrevoke();
    if hasBoost then
		local flowData = C_CharacterServices.GetCharacterServiceDisplayData(boostType);
		CharacterUpgradePopup_BeginCharacterUpgradeFlow(flowData, guid);
    else
		local purchasableBoostType = C_CharacterServices.GetActiveCharacterUpgradeBoostType();
        CharacterSelect_ShowStoreFrameForBoostType(purchasableBoostType, guid, "forUnrevokeBoost");
    end
end

function CharacterSelect_ShowBoostUnlockDialog(guid)
    local isTrialBoost, isTrialBoostLocked, revokedCharacterUpgrade, _, _, _, isExpansionTrialCharacter = select(22, GetCharacterInfoByGUID(guid));

    if isTrialBoost and isTrialBoostLocked then
        CharacterSelect_CheckApplyBoostToUnlockTrialCharacter(guid);
        return true;
	elseif isExpansionTrialCharacter then
        CharacterSelect_CheckApplyBoostToUnlockTrialCharacter(guid);
        return true;
    elseif revokedCharacterUpgrade then
        CharacterSelect_CheckApplyBoostToUnrevokeBoost(guid);
        return true;
    end

    return false;
end

CharacterSelectMailIndicationButtonMixin = {};

function CharacterSelectMailIndicationButtonMixin:OnEnter()
	if #self.mailSenders >= 1 then
		GlueTooltip:SetOwner(self, "ANCHOR_LEFT");
		FormatUnreadMailTooltip(GlueTooltip, HAVE_MAIL_FROM, self.mailSenders);
		GlueTooltip:Show();
	end
end

function CharacterSelectMailIndicationButtonMixin:OnLeave()
	GlueTooltip:Hide();
end

function CharacterSelectMailIndicationButtonMixin:SetMailSenders(mailSenders)
	self.mailSenders = mailSenders;
end

CharSelectServicesFlowFrameMixin = {};

function CharSelectServicesFlowFrameMixin:SetErrorMessage(msg)
	self.ErrorMessageContainer.Text:SetText(msg);
	self.ErrorMessageContainer.Text:SetJustifyH("LEFT");
	self.ErrorMessageContainer.fullText = msg;

	local isTruncated = self.ErrorMessageContainer.Text:IsTruncated();
	self.ErrorMessageContainer.isTruncated = isTruncated;
	if isTruncated then
		-- HACK, avoid global string hotfix:
		local errorLink = string.gsub('[' .. BLIZZARD_STORE_VAS_ERROR_LABEL .. ']', ':', '');
		self.ErrorMessageContainer.Text:SetText(errorLink);
		self.ErrorMessageContainer.Text:SetJustifyH("CENTER");
	end
end

function CharSelectServicesFlowFrameMixin:ClearErrorMessage()
	self.ErrorMessageContainer.Text:SetText("");
	self.ErrorMessageContainer.fullText = nil;
	self.ErrorMessageContainer.isTruncated = nil;
end

FlowErrorContainerMixin = {};

function FlowErrorContainerMixin:OnEnter()
	if self.isTruncated then
		local tooltip = GetAppropriateTooltip();
		tooltip:SetOwner(self, "ANCHOR_LEFT");
		GameTooltip_SetTitle(tooltip, BLIZZARD_STORE_VAS_ERROR_LABEL);
		GameTooltip_AddErrorLine(tooltip, self.fullText);
		tooltip:Show();
	end
end

function FlowErrorContainerMixin:OnLeave()
	GetAppropriateTooltip():Hide();
end

function CharSelectEnterWorldButton_OnEnter(button)
	GlueTooltip:SetOwner(button, "ANCHOR_LEFT", 4, -8);
	if ( not button:IsEnabled() and IsNameReservationOnly() ) then
		local hours = GetLaunchETA();
        local text;
		if (hours > 0) then
			text = LAUNCH_ETA:format(hours);
		else
			text = LAUNCH_ETA_SOON;
		end

		GlueTooltip:SetText(text);
	elseif ( not button:IsEnabled() and button.disabledTooltip ) then
		-- This triggers the normal UIButtonTemplate disabled tooltip path
		button:OnEnter(button);
	else
		GlueTooltip:Hide();
	end
end

function CharSelectEnterWorldButton_OnLeave(button)
	GlueTooltip:Hide();
end

function CharacterSelect_ShowSeasonNotification()
	if(not RealmCallout) then
		return;
	end

	if(GetSoMNotificationEnabled() and GetCVar("seenSoMNotification") == "0" and not C_Seasons.HasActiveSeason()) then
		RealmCallout:Show();
		local offsetX, offsetY = 3, 1;
		GlowEmitterFactory:Show(CharSelectChangeRealmButton, GlowEmitterMixin.Anims.NPE_RedButton_GreenGlow, offsetX, offsetY);
		RealmCallout.Text:SetText(SEASON_CHARACTER_SELECT_NOTIFICATIONS[Enum.SeasonID.SeasonOfMastery]);
	else
		RealmCallout:Hide();
	end
end

function isInBoostFlow()
	return CharSelectServicesFlowFrame:IsShown();
end

-- Reincarnation

function Reincarnation_StartReincarnation()
    local charIndex = CharacterSelect.selectedIndex;
    local name, _, _, className, _, level, _, _, _, _, _, _, _, _, guid = GetCharacterInfo(GetCharIDFromIndex(charIndex));
    PlaySound(SOUNDKIT.GS_CHARACTER_SELECTION_CREATE_NEW);
    C_CharacterCreation.ClearCharacterTemplate();
    C_Reincarnation.StartReincarnation(guid, name, className, level);
    CharacterCreateNameEdit:SetText(name);
    GlueParent_SetScreen("charcreate");
end
