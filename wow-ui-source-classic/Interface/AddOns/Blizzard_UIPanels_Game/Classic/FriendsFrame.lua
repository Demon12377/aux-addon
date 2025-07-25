FRIENDS_TO_DISPLAY = 10;
FRIENDS_FRAME_FRIEND_HEIGHT = 34;
IGNORES_TO_DISPLAY = 19;
FRIENDS_FRAME_IGNORE_HEIGHT = 16;
PENDING_INVITES_TO_DISPLAY = 4;
PENDING_BUTTON_MIN_HEIGHT = 92;
FRIENDS_FRIENDS_TO_DISPLAY = 11;
FRIENDS_FRAME_FRIENDS_FRIENDS_HEIGHT = 16;
WHOS_TO_DISPLAY = 17;
FRIENDS_FRAME_WHO_HEIGHT = 16;
MAX_WHOS_FROM_SERVER = 50;
GUILDMEMBERS_TO_DISPLAY = 13;
FRIENDS_FRAME_GUILD_HEIGHT = 14;
GUILD_DETAIL_NORM_HEIGHT = 195
GUILD_DETAIL_OFFICER_HEIGHT = 255
GUILD_NUM_RANK_FLAGS = 13;

FRIENDS_SCROLLFRAME_HEIGHT = 307;
FRIENDS_BUTTON_TYPE_DIVIDER = 1;
FRIENDS_BUTTON_TYPE_BNET = 2;
FRIENDS_BUTTON_TYPE_WOW = 3;
FRIENDS_BUTTON_TYPE_INVITE = 4;
FRIENDS_BUTTON_TYPE_INVITE_HEADER = 5;
FRIENDS_BUTTON_HEIGHTS = {
	[FRIENDS_BUTTON_TYPE_DIVIDER] = 16,
	[FRIENDS_BUTTON_TYPE_BNET] = 34,
	[FRIENDS_BUTTON_TYPE_WOW] = 34,
	[FRIENDS_BUTTON_TYPE_INVITE] = 34,
	[FRIENDS_BUTTON_TYPE_INVITE_HEADER] = 31,
}

FRIENDS_TEXTURE_ONLINE = "Interface\\FriendsFrame\\StatusIcon-Online";
FRIENDS_TEXTURE_AFK = "Interface\\FriendsFrame\\StatusIcon-Away";
FRIENDS_TEXTURE_DND = "Interface\\FriendsFrame\\StatusIcon-DnD";
FRIENDS_TEXTURE_OFFLINE = "Interface\\FriendsFrame\\StatusIcon-Offline";
FRIENDS_TEXTURE_BROADCAST = "Interface\\FriendsFrame\\BroadcastIcon";
SQUELCH_TYPE_IGNORE = 1;
SQUELCH_TYPE_BLOCK_INVITE = 2;
FRIENDS_FRIENDS_POTENTIAL = 1;
FRIENDS_FRIENDS_MUTUAL = 2;
FRIENDS_FRIENDS_ALL = 3;
FRIENDS_TOOLTIP_MAX_GAME_ACCOUNTS = 5;
FRIENDS_TOOLTIP_MAX_WIDTH = 200;
FRIENDS_TOOLTIP_MARGIN_WIDTH = 12;

ADDFRIENDFRAME_WOWHEIGHT = 218;
ADDFRIENDFRAME_BNETHEIGHT = 296;

FRIEND_TABS_MAX_WIDTH = 280;

FRIEND_TAB_COUNT = 4; -- This is the max number of tabs we can have shown. (Some may be hidden.)
FRIEND_TAB_BASE_COUNT = 3; -- This is the base number of tabs we're guaranteed to have shown.
FRIEND_TAB_FRIENDS = 1;
FRIEND_TAB_WHO = 2;
FRIEND_TAB_GUILD = 3; -- May or may not be shown.
FRIEND_TAB_RAID = 4;
FRIEND_HEADER_TAB_FRIENDS = 1;
FRIEND_HEADER_TAB_IGNORE = 2;

PENDING_GUILDBANK_PERMISSIONS = {};

local INVITE_RESTRICTION_NO_GAME_ACCOUNTS = 0;
local INVITE_RESTRICTION_CLIENT = 1;
local INVITE_RESTRICTION_LEADER = 2;
local INVITE_RESTRICTION_FACTION = 3;
local INVITE_RESTRICTION_REALM = 4;
local INVITE_RESTRICTION_INFO = 5;
local INVITE_RESTRICTION_WOW_PROJECT_ID = 6;
local INVITE_RESTRICTION_WOW_PROJECT_MAINLINE = 7;
local INVITE_RESTRICTION_WOW_PROJECT_CLASSIC = 8;
local INVITE_RESTRICTION_WOW_PROJECT_BCC = 9;
local INVITE_RESTRICTION_WOW_PROJECT_WRATH = 10;
local INVITE_RESTRICTION_WOW_PROJECT_CATACLYSM = 11;
local INVITE_RESTRICTION_WOW_PROJECT_MISTS = 12;
local INVITE_RESTRICTION_NONE = 13;

local FriendListEntries = { };
local playerNativeRealmID;
local playerRealmName;
local playerFactionGroup;

local ONE_MINUTE = 60;
local ONE_HOUR = 60 * ONE_MINUTE;
local ONE_DAY = 24 * ONE_HOUR;
local ONE_MONTH = 30 * ONE_DAY;
local ONE_YEAR = 12 * ONE_MONTH;
-- local ONE_MILLENIUM = 1000 * ONE_YEAR; 	for the future

local whoSortValue = 1;

CVarCallbackRegistry:SetCVarCachable("useClassicGuildUI");

FRIENDSFRAME_SUBFRAMES = { "FriendsListFrame", "IgnoreListFrame", "WhoFrame", "GuildFrame", "RaidFrame" };
function FriendsFrame_ShowSubFrame(frameName)
	for index, value in pairs(FRIENDSFRAME_SUBFRAMES) do
		if ( value == frameName ) then
			_G[value]:Show()
		elseif ( value == "RaidFrame" ) then
			if ( RaidFrame:GetParent() == FriendsFrame ) then
				RaidFrame:Hide();
			end
		else
			_G[value]:Hide();
		end
	end
end

function FriendsFrame_SummonButton_OnShow (self)
	FriendsFrame_SummonButton_Update(self);
end

function FriendsFrame_ShouldShowSummonButton(self)
	--returns shouldShow, enabled
	local id = self:GetParent().id;
	if ( not id ) then
		return false, false;
	end

	local enable = false;
	local bType = self:GetParent().buttonType;
	if ( self:GetParent().buttonType == FRIENDS_BUTTON_TYPE_WOW ) then
		--Get the information by WoW friends list ID (not BNet id.)
		local info = C_FriendList.GetFriendInfoByIndex(id);

		if ( not info.isReferAFriend ) then
			return false, false;
		end

		return true, C_RecruitAFriend.CanSummonFriend(info.name);
	elseif ( self:GetParent().buttonType == FRIENDS_BUTTON_TYPE_BNET ) then
		--Get the information by BNet friends list ID.
		local bnetIDAccount, accountName, battleTag, isBattleTag, characterName, bnetIDGameAccount, client, isOnline, lastOnline, isAFK, isDND, messageText, noteText, isRIDFriend, messageTime, canSoR, isReferAFriend, canSummonFriend = BNGetFriendInfo(id);

		if ( not isReferAFriend ) then
			return false, false;
		end

		return true, canSummonFriend;
	else
		return false, false;
	end
end

function FriendsFrame_SummonButton_Update (self)
	local shouldShow, enable = FriendsFrame_ShouldShowSummonButton(self);
	self:SetShown(shouldShow);

	local start, duration = C_RecruitAFriend.GetSummonFriendCooldown();

	if ( duration > 0 ) then
		self.duration = duration;
		self.start = start;
	else
		self.duration = nil;
		self.start = nil;
	end


	local normalTexture = self:GetNormalTexture();
	local pushedTexture = self:GetPushedTexture();
	self.enabled = enable;
	if ( enable ) then
		normalTexture:SetVertexColor(1.0, 1.0, 1.0);
		pushedTexture:SetVertexColor(1.0, 1.0, 1.0);
	else
		normalTexture:SetVertexColor(0.4, 0.4, 0.4);
		pushedTexture:SetVertexColor(0.4, 0.4, 0.4);
	end
	CooldownFrame_Set(_G[self:GetName().."Cooldown"], start, duration, ((enable and 0) or 1));
end

function FriendsFrame_ClickSummonButton (self)
	local id = self:GetParent().id;
	if ( not id ) then
		return;
	end

	if ( self:GetParent().buttonType == FRIENDS_BUTTON_TYPE_WOW ) then
		--Summon by WoW friends list ID (not BNet id.)
		local info = C_FriendList.GetFriendInfoByIndex(id);

		C_RecruitAFriend.SummonFriend(info.name);
	elseif ( self:GetParent().buttonType == FRIENDS_BUTTON_TYPE_BNET ) then
		--Summon by BNet friends list ID (index in this case.)
		BNSummonFriendByIndex(id);
	end
end

function FriendsFrame_ShowDropdown(name, connected, lineID, chatType, chatFrame, friendsList, isMobile, communityClubID, communityStreamID, communityEpoch, communityPosition, guid, whoIndex)
	if connected or friendsList then
		local contextData = 
		{	
			name = name,
			fromFriendFrame = true,
			friendsList = friendsList,
			lineID = lineID,
			communityClubID = communityClubID,
			communityStreamID = communityStreamID,
			communityEpoch = communityEpoch,
			communityPosition = communityPosition,
			chatType = chatType,
			chatTarget = name,
			chatFrame = chatFrame,
			bnetIDAccount = nil,
			isMobile = isMobile,
			guid = guid,
			whoIndex = whoIndex,
		};

		local which = connected and "FRIEND" or "FRIEND_OFFLINE";
		UnitPopup_OpenMenu(which, contextData);
	end
end

function FriendsFrame_ShowBNDropdown(name, connected, lineID, chatType, chatFrame, friendsList, bnetIDAccount, communityClubID, communityStreamID, communityEpoch, communityPosition)
	if connected or friendsList then
		local contextData = 
		{	
			name = name,
			fromFriendFrame = true,
			friendsList = friendsList,
			lineID = lineID,
			communityClubID = communityClubID,
			communityStreamID = communityStreamID,
			communityEpoch = communityEpoch,
			communityPosition = communityPosition,
			chatType = chatType,
			chatTarget = name,
			chatFrame = chatFrame,
			bnetIDAccount = bnetIDAccount,
			isMobile = mobile,
		};

		local which = connected and "BN_FRIEND" or "BN_FRIEND_OFFLINE";
		UnitPopup_OpenMenu(which, contextData);
	end
end

function FriendsFrame_CheckDethroneStatus()
	local canReplaceGM = CanReplaceGuildMaster();
	GuildFrameImpeachButton:SetShown(canReplaceGM);
	GuildFrameControlButton:SetShown(not canReplaceGM);
end

function FriendsFrame_OnLoad(self)
	PanelTemplates_SetNumTabs(self, FRIEND_TAB_COUNT);
	self.selectedTab = FRIEND_TAB_FRIENDS;
	PanelTemplates_UpdateTabs(self);
	self:RegisterEvent("FRIENDLIST_UPDATE");
	self:RegisterEvent("IGNORELIST_UPDATE");
	self:RegisterEvent("WHO_LIST_UPDATE");
	self:RegisterEvent("GROUP_ROSTER_UPDATE");
	self:RegisterEvent("PLAYER_GUILD_UPDATE");
	self:RegisterEvent("GUILD_MOTD");
	self:RegisterEvent("PLAYER_FLAGS_CHANGED");
	self:RegisterEvent("BN_FRIEND_LIST_SIZE_CHANGED");
	self:RegisterEvent("BN_FRIEND_INFO_CHANGED");
	self:RegisterEvent("BN_FRIEND_INVITE_LIST_INITIALIZED");
	self:RegisterEvent("BN_FRIEND_INVITE_ADDED");
	self:RegisterEvent("BN_FRIEND_INVITE_REMOVED");
	self:RegisterEvent("BN_CUSTOM_MESSAGE_CHANGED");
	self:RegisterEvent("BN_CUSTOM_MESSAGE_LOADED");
	self:RegisterEvent("BN_BLOCK_LIST_UPDATED");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("BN_CONNECTED");
	self:RegisterEvent("BN_DISCONNECTED");
	self:RegisterEvent("BN_INFO_CHANGED");
	self:RegisterEvent("SPELL_UPDATE_COOLDOWN");
	self:RegisterEvent("BATTLETAG_INVITE_SHOW");
	self:RegisterEvent("GUILD_ROSTER_UPDATE");
	self:RegisterEvent("GROUP_JOINED");
	self:RegisterEvent("GROUP_LEFT");
	self:RegisterEvent("GUILD_RENAME_REQUIRED");
	self:RegisterEvent("REQUIRED_GUILD_RENAME_RESULT");
	self:RegisterEvent("GUILD_EVENT_LOG_UPDATE");
	self.playerStatusFrame = 1;
	self.selectedFriend = 1;
	self.selectedIgnore = 1;
	-- guild
	self.guildStatus = 0;
	GuildFrame.notesToggle = 1;
	GuildFrame.selectedGuildMember = 0;
	GuildFrame.hasForcedNameChange = GetGuildRenameRequired();
	SetGuildRosterSelection(0);
	local currentGuildMOTD = GetGuildRosterMOTD();
	GuildFrameNotesText:SetText(currentGuildMOTD);
	GuildMemberDetailRankText:SetPoint("RIGHT", GuildFramePromoteButton, "LEFT");
	-- friends list
	local scrollFrame = FriendsFrameFriendsScrollFrame;
	scrollFrame.update = FriendsFrame_UpdateFriends;
	scrollFrame.dynamic = FriendsList_GetScrollFrameTopButton;
	scrollFrame.dividerPool = CreateFramePool("FRAME", self, "FriendsFrameFriendDividerTemplate");
	scrollFrame.invitePool = CreateFramePool("FRAME", self, "FriendsFrameFriendInviteTemplate");
	-- can't do this in XML because we're inheriting from a template
	scrollFrame.PendingInvitesHeaderButton:SetParent(scrollFrame.ScrollChild);
	FriendsFrameFriendsScrollFrameScrollBarTrack:Hide();
	FriendsFrameFriendsScrollFrameScrollBar.doNotHide = true;
	HybridScrollFrame_CreateButtons(scrollFrame, "FriendsFrameButtonTemplate");
	FriendsFrameIcon:SetTexture("Interface\\FriendsFrame\\FriendsFrameScrollIcon");

	GuildControlPopupFrame.numSkipUpdates = 0;

	FriendsFrameBroadcastInputClearButton.icon:SetVertexColor(FRIENDS_BNET_NAME_COLOR.r, FRIENDS_BNET_NAME_COLOR.g, FRIENDS_BNET_NAME_COLOR.b);
	if ( not BNFeaturesEnabled() ) then
		FriendsFrameBattlenetFrame:Hide();
		FriendsFrameBroadcastInput:Hide();
	end

	--Create lists of buttons for various subframes
	for i = 2, 19 do
		local button = CreateFrame("Button", "FriendsFrameIgnoreButton"..i, IgnoreListFrame, "FriendsFrameIgnoreButtonTemplate");
		button:SetPoint("TOP", _G["FriendsFrameIgnoreButton"..(i-1)], "BOTTOM");
	end
	for i = 2, 17 do
		local button = CreateFrame("Button", "WhoFrameButton"..i, WhoFrame, "FriendsFrameWhoButtonTemplate");
		button:SetID(i);
		button:SetPoint("TOP", _G["WhoFrameButton"..(i-1)], "BOTTOM");
	end
end

function FriendsFrame_OnEvent(self, event, ...)
	if ( event == "SPELL_UPDATE_COOLDOWN" ) then
		if ( self:IsShown() ) then
			local buttons = FriendsFrameFriendsScrollFrame.buttons;
			for _, button in pairs(buttons) do
				if ( button.summonButton:IsShown() ) then
					FriendsFrame_SummonButton_Update(button.summonButton);
				end
			end
		end
	elseif ( event == "FRIENDLIST_UPDATE" or event == "GROUP_ROSTER_UPDATE" ) then
		FriendsList_Update();
	elseif ( event == "BN_FRIEND_LIST_SIZE_CHANGED" or event == "BN_FRIEND_INFO_CHANGED" ) then
		FriendsList_Update();
		-- update Friends of Friends
		local bnetIDAccount = ...;
		if ( event == "BN_FRIEND_LIST_SIZE_CHANGED" and bnetIDAccount ) then
			FriendsFriendsFrame.requested[bnetIDAccount] = nil;
			if ( FriendsFriendsFrame:IsShown() ) then
				FriendsFriendsList_Update();
			end
		end
	elseif ( event == "BN_CUSTOM_MESSAGE_CHANGED" ) then
		local arg1 = ...;
		if ( arg1 ) then	--There is no bnetIDAccount given if this is ourself.
			FriendsList_Update();
		else
			FriendsFrameBattlenetFrame_UpdateBroadcast();
		end
	elseif ( event == "BN_CUSTOM_MESSAGE_LOADED" ) then
		FriendsFrameBattlenetFrame_UpdateBroadcast();
	elseif ( event == "BN_FRIEND_INVITE_ADDED" ) then
		-- flash the invites header if collapsed
		local collapsed = GetCVarBool("friendInvitesCollapsed");
		if ( collapsed ) then
			FriendsFrameFriendsScrollFrame.PendingInvitesHeaderButton.Flash.Anim:Play();
		end
		FriendsList_Update();
	elseif ( event == "BN_FRIEND_INVITE_LIST_INITIALIZED" ) then
		FriendsList_Update();
	elseif ( event == "BN_FRIEND_INVITE_REMOVED" ) then
		FriendsList_Update();
	elseif ( event == "IGNORELIST_UPDATE" or event == "BN_BLOCK_LIST_UPDATED" ) then
		IgnoreList_Update();
	elseif ( event == "WHO_LIST_UPDATE" ) then
		WhoFrame.selectedWho = nil;
		WhoList_Update();
		FriendsFrame_Update();
	elseif ( event == "PLAYER_FLAGS_CHANGED" or event == "BN_INFO_CHANGED") then
		FriendsFrameStatusDropdown:GenerateMenu();
		FriendsFrame_CheckBattlenetStatus();
	elseif ( event == "PLAYER_ENTERING_WORLD" or event == "BN_CONNECTED" or event == "BN_DISCONNECTED") then
		FriendsFrame_CheckBattlenetStatus();
		-- We want to remove any friends from the frame so they don't linger when it's first re-opened.
		if (event == "BN_DISCONNECTED") then
			FriendsList_Update(true);
		end
	elseif ( event == "BATTLETAG_INVITE_SHOW" ) then
		BattleTagInviteFrame_Show(...);
	elseif ( event == "SOCIAL_QUEUE_UPDATE" or event == "GROUP_LEFT" or event == "GROUP_JOINED" ) then
		if ( self:IsVisible() ) then
			FriendsFrame_Update(); --TODO - Only update the buttons that need updating
		end
	elseif ( event == "GUILD_ROSTER_UPDATE" ) then
		FriendsFrame_CheckDethroneStatus();

		GuildInfoFrame.cachedText = nil;
		if ( GuildFrame:IsShown() ) then
			local arg1 = ...;
			if ( arg1 ) then
				C_GuildInfo.GuildRoster();
			end
			GuildStatus_Update();
			FriendsFrame_Update();
			GuildControlPopupFrame_Initialize();
		end
		if ( GuildEventLogFrame:IsShown() ) then
			QueryGuildEventLog();
		end
	elseif ( event == "PLAYER_GUILD_UPDATE" ) then
		if ( FriendsFrame:IsVisible() ) then
			InGuildCheck();
		end
		if ( not IsInGuild() ) then
			GuildControlPopupFrame.initialized = false;
		end
	elseif ( event == "GUILD_MOTD") then
		local currentGuildMOTD = ...;
		GuildFrameNotesText:SetText(currentGuildMOTD);
	elseif ( event == "GUILD_RENAME_REQUIRED" ) then
		GuildFrame.hasForcedNameChange = ...;
		GuildFrame_CheckName();
	elseif ( event == "REQUIRED_GUILD_RENAME_RESULT" ) then
		local success = ...
		if ( success ) then
			GuildFrame.hasForcedNameChange = GetGuildRenameRequired();
			GuildFrame_CheckName();
		else
			UIErrorsFrame:AddMessage(ERR_GUILD_NAME_INVALID, 1.0, 0.1, 0.1, 1.0);
		end
	elseif ( event == "GUILD_EVENT_LOG_UPDATE" ) then
		GuildEventLog_Update();
	end
end

function FriendsFrame_InviteOrRequestToJoin(guid, gameAccountID)
	local inviteType = GetDisplayedInviteType(guid);
	if ( inviteType == "INVITE" or inviteType == "SUGGEST_INVITE" ) then
		if inviteType == "SUGGEST_INVITE" and C_PartyInfo.IsPartyFull() then
			ChatFrame_DisplaySystemMessageInPrimary(ERR_GROUP_FULL);
			return;
		end

		BNInviteFriend(gameAccountID);
	elseif ( inviteType == "REQUEST_INVITE" ) then
		BNRequestInviteFriend(gameAccountID);
	end
end

function FriendsFrame_OnShow()
	FriendsFrame_UpdateVisibleTabs();
	FriendsList_Update(true);
	FriendsFrame_Update();
	UpdateMicroButtons();
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
	C_GuildInfo.GuildRoster();
	InGuildCheck();
	FriendsFrame_CheckDethroneStatus();
end

function FriendsFrame_Update()
	local selectedTab = PanelTemplates_GetSelectedTab(FriendsFrame) or FRIEND_TAB_FRIENDS;

	FriendsTabHeader:SetShown(selectedTab == FRIEND_TAB_FRIENDS);

	if selectedTab == FRIEND_TAB_FRIENDS then
		local selectedHeaderTab = PanelTemplates_GetSelectedTab(FriendsTabHeader) or FRIEND_HEADER_TAB_FRIENDS;

		ButtonFrameTemplate_ShowButtonBar(FriendsFrame);
		FriendsFrameInset:SetPoint("TOPLEFT", 4, -83);

		if selectedHeaderTab == FRIEND_HEADER_TAB_FRIENDS then
			C_FriendList.ShowFriends();
			FriendsFrameTitleText:SetText(FRIENDS_LIST);
			FriendsFrame_ShowSubFrame("FriendsListFrame");
		elseif selectedHeaderTab == FRIEND_HEADER_TAB_QUICK_JOIN then
			FriendsFrameTitleText:SetText(QUICK_JOIN);
			FriendsFrame_ShowSubFrame("QuickJoinFrame");
		elseif selectedHeaderTab == FRIEND_HEADER_TAB_IGNORE then
			FriendsFrameIgnorePlayerButton:SetWidth(131);
			FriendsFrameUnsquelchButton:SetWidth(134);
			FriendsFrameTitleText:SetText(IGNORE_LIST);
			FriendsFrame_ShowSubFrame("IgnoreListFrame");
			IgnoreList_Update();
		end
	elseif ( selectedTab == FRIEND_TAB_WHO ) then
		ButtonFrameTemplate_ShowButtonBar(FriendsFrame);
		FriendsFrameInset:SetPoint("TOPLEFT", 4, -80);
		FriendsFrameTitleText:SetText(WHO_LIST);
		FriendsFrame_ShowSubFrame("WhoFrame");
		WhoList_Update();
	elseif ( selectedTab == FRIEND_TAB_GUILD ) then
		FriendsFrameInset:SetPoint("TOPLEFT", 4, -80);
		local guildName;
		guildName = GetGuildInfo("player");
		if (guildName) then
			FriendsFrameTitleText:SetText(guildName);
		end
		FriendsFrame_ShowSubFrame("GuildFrame");
		GuildStatus_Update();
		GuildFrame.hasForcedNameChange = GetGuildRenameRequired();
		GuildFrame_CheckName();
	elseif ( selectedTab == FRIEND_TAB_RAID ) then
		ButtonFrameTemplate_ShowButtonBar(FriendsFrame);
		FriendsFrameInset:SetPoint("TOPLEFT", 4, -60);
		FriendsFrameTitleText:SetText(RAID);
		ClaimRaidFrame(FriendsFrame);
		FriendsFrame_ShowSubFrame("RaidFrame");
	end
end

function FriendsFrame_OnHide()
	UpdateMicroButtons();
	PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE);
	RaidInfoFrame:Hide();
	for index, value in pairs(FRIENDSFRAME_SUBFRAMES) do
		if ( value == "RaidFrame" ) then
			if ( RaidFrame:GetParent() == FriendsFrame ) then
				RaidFrame:Hide();
			end
		else
			_G[value]:Hide();
		end
	end
	FriendsFriendsFrame:Hide();
end

FriendsTabHeaderMixin = {};


function FriendsTabHeaderMixin:OnLoad()
	PanelTemplates_SetNumTabs(self, 2);
	PanelTemplates_SetTab(self, 1);
	FriendsTabHeader_ResizeTabs();

	local bnetAFK, bnetDND = select(5, BNGetInfo());
	if bnetAFK then
		self.bnStatus = FRIENDS_TEXTURE_AFK;
	elseif bnetDND then
		self.bnStatus = FRIENDS_TEXTURE_DND;
	else
		self.bnStatus = FRIENDS_TEXTURE_ONLINE;
	end

	local function IsSelected(status)
		return self.bnStatus == status;
	end

	local function SetSelected(status)
		if status ~= self.bnStatus then
			self.bnStatus = status;

			if status == FRIENDS_TEXTURE_ONLINE then
				BNSetAFK(false);
				BNSetDND(false);
			elseif status == FRIENDS_TEXTURE_AFK then
				BNSetAFK(true);
			elseif status == FRIENDS_TEXTURE_DND then
				BNSetDND(true);
			end
		end
	end

	local function CreateRadio(rootDescription, text, status)
		local radio = rootDescription:CreateButton(text, nop, status);
		radio:SetIsSelected(IsSelected);
		radio:SetResponder(SetSelected);
	end

	self.StatusDropdown:SetWidth(61);
	self.StatusDropdown:SetupMenu(function(dropdown, rootDescription)
		rootDescription:SetTag("MENU_FRIENDS_STATUS");

		local optionText = "\124T%s.tga:16:16:0:0\124t %s";
		
		local onlineText = string.format(optionText, FRIENDS_TEXTURE_ONLINE, FRIENDS_LIST_AVAILABLE);
		CreateRadio(rootDescription, onlineText, FRIENDS_TEXTURE_ONLINE);

		local afkText = string.format(optionText, FRIENDS_TEXTURE_AFK, FRIENDS_LIST_AWAY);
		CreateRadio(rootDescription, afkText, FRIENDS_TEXTURE_AFK);

		local dndText = string.format(optionText, FRIENDS_TEXTURE_DND, FRIENDS_LIST_BUSY);
		CreateRadio(rootDescription, dndText, FRIENDS_TEXTURE_DND);
	end);

	self.StatusDropdown:SetSelectionTranslator(function(selection)
		return string.format("\124T%s.tga:16:16:0:0\124t", selection.data);
	end);

	self.StatusDropdown:SetScript("OnEnter", function()
		local statusText;
		if ( self.bnStatus == FRIENDS_TEXTURE_ONLINE ) then
			statusText = FRIENDS_LIST_AVAILABLE;
		elseif ( self.bnStatus == FRIENDS_TEXTURE_AFK ) then
			statusText = FRIENDS_LIST_AWAY;
		elseif ( self.bnStatus == FRIENDS_TEXTURE_DND ) then
			statusText = FRIENDS_LIST_BUSY;
		end

		GameTooltip:SetOwner(self.StatusDropdown, "ANCHOR_RIGHT", -18, 0);
		GameTooltip:SetText(format(FRIENDS_LIST_STATUS_TOOLTIP, statusText));
		GameTooltip:Show();	
	end);
	self.StatusDropdown:SetScript("OnLeave", GameTooltip_Hide);
end

function FriendsTabHeader_ClickTab(tab)
	PanelTemplates_Tab_OnClick(tab, FriendsTabHeader);
	FriendsTabHeader_ResizeTabs();
	FriendsFrame_Update();
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
end

function FriendsTabHeader_ResizeTabs()
	PanelTemplates_ResizeTabsToFit(FriendsTabHeader, FRIEND_TABS_MAX_WIDTH);
end

function FriendsListFrame_OnShow(self)
	ProductChoiceFrame_OnFriendsListShown();
end

function FriendsListFrame_OnHide(self)
	FriendsList_ClosePendingInviteDialogs();
end

function FriendsListFrame_ToggleInvites()
	local collapsed = GetCVarBool("friendInvitesCollapsed");
	SetCVar("friendInvitesCollapsed", not collapsed);
	FriendsFrameFriendsScrollFrame.PendingInvitesHeaderButton.Flash.Anim:Stop();
	FriendsList_Update();
end

FriendsFrameInviteTemplateMixin = {};

function FriendsFrameInviteTemplateMixin:OnLoad()
	self.DeclineButton:SetupMenu(function(dropdown, rootDescription)
		rootDescription:SetTag("MENU_FRIENDS_INVITE_DECLINE");

		rootDescription:CreateButton(DECLINE, function()
			FriendsList_ClosePendingInviteDialogs();
			BNDeclineFriendInvite(self.inviteID);
		end);

		rootDescription:CreateButton(REPORT_PLAYER, function()
			local bnetIDAccount, name = BNGetFriendInviteInfo(self.inviteIndex);
			local playerLocation = PlayerLocation:CreateFromBattleNetID(bnetIDAccount);
			local reportInfo = ReportInfo:CreateReportInfoFromType(Enum.ReportType.Friend);
			ReportFrame:InitiateReport(reportInfo, name, playerLocation, bnetIDAccount ~= nil);
		end);

		if StaticPopup_Show then
			rootDescription:CreateButton(BLOCK_INVITES, function()
				local inviteID, accountName = BNGetFriendInviteInfo(self.inviteIndex);
				local dialog = StaticPopup_Show("CONFIRM_BLOCK_INVITES", accountName);
				if dialog then
					dialog.data = inviteID;
				end
			end);
		end
	end);
end

function FriendsList_ClosePendingInviteDialogs()
	StaticPopup_Hide("CONFIRM_BLOCK_INVITES");
	StaticPopupSpecial_Hide(PlayerReportFrame);
end

function FriendsList_GetScrollFrameTopButton(offset)
	local usedHeight = 0;
	for i = 1, #FriendListEntries do
		local buttonHeight = FRIENDS_BUTTON_HEIGHTS[FriendListEntries[i].buttonType];
		if ( usedHeight + buttonHeight >= offset ) then
			return i - 1, offset - usedHeight;
		else
			usedHeight = usedHeight + buttonHeight;
		end
	end
end

function FriendsList_CanWhisperFriend(friendType, friendIndex)
	if friendType == FRIENDS_BUTTON_TYPE_BNET then
		return true;
	elseif friendType == FRIENDS_BUTTON_TYPE_WOW then
		local info = C_FriendList.GetFriendInfoByIndex(friendIndex);
		return info.connected;
	end

	return false;
end

function FriendsList_Update(forceUpdate)
	local numBNetTotal, numBNetOnline = BNGetNumFriends();
	local numBNetOffline = numBNetTotal - numBNetOnline;
	local numWoWTotal = C_FriendList.GetNumFriends();
	local numWoWOnline = C_FriendList.GetNumOnlineFriends();
	local numWoWOffline = numWoWTotal - numWoWOnline;

	if ( not FriendsListFrame:IsShown() and not forceUpdate) then
		return;
	end

	local addButtonIndex = 0;
	local totalButtonHeight = 0;
	local function AddButtonInfo(buttonType, id)
		addButtonIndex = addButtonIndex + 1;
		if ( not FriendListEntries[addButtonIndex] ) then
			FriendListEntries[addButtonIndex] = { };
		end
		FriendListEntries[addButtonIndex].buttonType = buttonType;
		FriendListEntries[addButtonIndex].id = id;
		totalButtonHeight = totalButtonHeight + FRIENDS_BUTTON_HEIGHTS[buttonType];
	end

	-- invites
	local numInvites = BNGetNumFriendInvites();
	if ( numInvites > 0 ) then
		AddButtonInfo(FRIENDS_BUTTON_TYPE_INVITE_HEADER, nil);
		if ( not GetCVarBool("friendInvitesCollapsed") ) then
			for i = 1, numInvites do
				AddButtonInfo(FRIENDS_BUTTON_TYPE_INVITE, i);
			end
			-- add divider before friends
			if ( numBNetTotal + numWoWTotal > 0 ) then
				AddButtonInfo(FRIENDS_BUTTON_TYPE_DIVIDER, nil);
			end
		end
	end
	-- online WoW friends
	for i = 1, numWoWOnline do
		AddButtonInfo(FRIENDS_BUTTON_TYPE_WOW, i);
	end
	-- online Battlenet friends
	for i = 1, numBNetOnline do
		AddButtonInfo(FRIENDS_BUTTON_TYPE_BNET, i);
	end
	-- divider between online and offline friends
	if ( (numBNetOnline > 0 or numWoWOnline > 0) and (numBNetOffline > 0 or numWoWOffline > 0) ) then
		AddButtonInfo(FRIENDS_BUTTON_TYPE_DIVIDER, nil);
	end
	-- offline WoW friends
	for i = 1, numWoWOffline do
		AddButtonInfo(FRIENDS_BUTTON_TYPE_WOW, i + numWoWOnline);
	end
	-- offline Battlenet friends
	for i = 1, numBNetOffline do
		AddButtonInfo(FRIENDS_BUTTON_TYPE_BNET, i + numBNetOnline);
	end

	FriendsFrameFriendsScrollFrame.totalFriendListEntriesHeight = totalButtonHeight;
	FriendsFrameFriendsScrollFrame.numFriendListEntries = addButtonIndex;

	-- selection
	local selectedFriend = 0;
	-- check that we have at least 1 friend
	if ( numBNetTotal + numWoWTotal > 0 ) then
		-- get friend
		if ( FriendsFrame.selectedFriendType == FRIENDS_BUTTON_TYPE_WOW ) then
			selectedFriend = C_FriendList.GetSelectedFriend();
		elseif ( FriendsFrame.selectedFriendType == FRIENDS_BUTTON_TYPE_BNET ) then
			selectedFriend = BNGetSelectedFriend();
		end
		-- set to first in list if no friend
		if ( not selectedFriend or selectedFriend == 0 ) then
			FriendsFrame_SelectFriend(FriendListEntries[1].buttonType, 1);
			selectedFriend = 1;
		end
		-- check if friend is online
		FriendsFrameSendMessageButton:SetEnabled(FriendsList_CanWhisperFriend(FriendsFrame.selectedFriendType, selectedFriend));
	else
		FriendsFrameSendMessageButton:Disable();
	end
	FriendsFrame.selectedFriend = selectedFriend;
	FriendsFrame_UpdateFriends();

	-- RID warning, upon getting the first RID invite
	local showRIDWarning = false;
	if ( numInvites > 0 and not GetCVarBool("pendingInviteInfoShown") ) then
		local _, _, _, _, _, _, isRIDEnabled = BNGetInfo();
		if ( isRIDEnabled ) then
			for i = 1, numInvites do
				local inviteID, accountName, isBattleTag = BNGetFriendInviteInfo(i);
				if ( not isBattleTag ) then
					-- found one
					showRIDWarning = true;
					break;
				end
			end
		end
	end
	if ( showRIDWarning ) then
		FriendsListFrame.RIDWarning:Show();
		FriendsFrameFriendsScrollFrame.scrollBar:Disable();
		FriendsFrameFriendsScrollFrame.scrollUp:Disable();
		FriendsFrameFriendsScrollFrame.scrollDown:Disable();
	else
		FriendsListFrame.RIDWarning:Hide();
	end
end

function IgnoreList_Update()
	local button;
	local numIgnores = C_FriendList.GetNumIgnores();
	local numBlocks = BNGetNumBlocked();

	-- Headers stuff
	local ignoredHeader, blockedHeader;
	if ( numIgnores > 0 ) then
		ignoredHeader = 1;
	else
		ignoredHeader = 0;
	end
	if ( numBlocks > 0 ) then
		blockedHeader = 1;
	else
		blockedHeader = 0;
	end

	local lastIgnoredIndex = numIgnores + ignoredHeader;
	local lastBlockedIndex = lastIgnoredIndex + numBlocks + blockedHeader;
	local numEntries = lastBlockedIndex;

	FriendsFrameIgnoredHeader:Hide();
	FriendsFrameBlockedInviteHeader:Hide();
	local numOnline = 0;

	-- selection stuff
	local selectedSquelchType = FriendsFrame.selectedSquelchType;
	local selectedSquelchIndex = 0 ;
	if ( selectedSquelchType == SQUELCH_TYPE_IGNORE ) then
		selectedSquelchIndex = C_FriendList.GetSelectedIgnore() or 0;
	elseif ( selectedSquelchType == SQUELCH_TYPE_BLOCK_INVITE ) then
		selectedSquelchIndex = BNGetSelectedBlock();
	end
	if ( selectedSquelchIndex == 0 ) then
		if ( numIgnores > 0 ) then
			FriendsFrame_SelectSquelched(SQUELCH_TYPE_IGNORE, 1);
			selectedSquelchType = SQUELCH_TYPE_IGNORE;
			selectedSquelchIndex = 1;
		elseif ( numBlocks > 0 ) then
			FriendsFrame_SelectSquelched(SQUELCH_TYPE_BLOCK_INVITE, 1);
			selectedSquelchType = SQUELCH_TYPE_BLOCK_INVITE;
			selectedSquelchIndex = 1;
		end
	end
	if ( selectedSquelchIndex > 0 ) then
		FriendsFrameUnsquelchButton:Enable();
	else
		FriendsFrameUnsquelchButton:Disable();
	end

	local scrollOffset = FauxScrollFrame_GetOffset(FriendsFrameIgnoreScrollFrame);
	local squelchedIndex;
	for i = 1, IGNORES_TO_DISPLAY, 1 do
		squelchedIndex = i + scrollOffset;
		button = _G["FriendsFrameIgnoreButton"..i];
		button.type = nil;
		if ( squelchedIndex == ignoredHeader ) then
			-- ignored header
			IgnoreList_SetHeader(FriendsFrameIgnoredHeader, button);
		elseif ( squelchedIndex <= lastIgnoredIndex ) then
			-- ignored
			button.index = squelchedIndex - ignoredHeader;
			local name = C_FriendList.GetIgnoreName(button.index);
			if ( not name ) then
				button.name:SetText(UNKNOWN);
			else
				button.name:SetText(name);
				button.type = SQUELCH_TYPE_IGNORE;
			end
		elseif ( blockedHeader == 1 and squelchedIndex == lastIgnoredIndex + 1 ) then
			-- blocked header
			IgnoreList_SetHeader(FriendsFrameBlockedInviteHeader, button);
		elseif ( squelchedIndex <= lastBlockedIndex ) then
			-- blocked
			button.index = squelchedIndex - lastIgnoredIndex - blockedHeader;
			local blockID, blockName = BNGetBlockedInfo(button.index);
			button.name:SetText(blockName);
			button.type = SQUELCH_TYPE_BLOCK_INVITE;
		end
		if ( selectedSquelchType == button.type and selectedSquelchIndex == button.index ) then
			button:LockHighlight();
			numOnline = numOnline + 1;
		else
			button:UnlockHighlight();
		end
		if ( squelchedIndex > numEntries ) then
			button:Hide();
		else
			button:Show();
		end
	end
	-- ScrollFrame stuff
	FauxScrollFrame_Update(FriendsFrameIgnoreScrollFrame, numEntries, IGNORES_TO_DISPLAY, FRIENDS_FRAME_IGNORE_HEIGHT );
end

function IgnoreList_SetHeader(header, parent)
	parent.name:SetText("");
	header:SetParent(parent);
	header:SetPoint("TOPLEFT", parent, 0, 0);
	header:Show();
end

function WhoList_Update()
	local numWhos, totalCount = C_FriendList.GetNumWhoResults();
	if (numWhos ~= WhoFrame.numWhos) then
		-- Moderate hack: if the number of who buttons has changed, selectedIndex might no longer be valid, so just clear it.
		-- The WHO_LIST_UPDATE handler also clears it, but that event doesn't fire if the Who Frame isn't shown.
		WhoFrame.selectedWho = nil;
	end
	-- If we're in the process of reporting someone from the Who Frame, back out since their index might change.
	if (PlayerReportFrame and PlayerReportFrame.playerLocation and PlayerReportFrame.playerLocation:IsWhoIndex()) then
		PlayerReportFrame:CancelReport();
	end

	WhoFrame.numWhos = numWhos;

	local name, guild, level, race, class, zone;
	local button, buttonText, classTextColor, classFileName;
	local columnTable;
	local whoOffset = FauxScrollFrame_GetOffset(WhoListScrollFrame);
	local whoIndex;
	local showScrollBar = nil;
	if ( numWhos > WHOS_TO_DISPLAY ) then
		showScrollBar = 1;
	end
	local displayedText = "";
	if ( totalCount > MAX_WHOS_FROM_SERVER ) then
		displayedText = format(WHO_FRAME_SHOWN_TEMPLATE, MAX_WHOS_FROM_SERVER);
	end
	WhoFrameTotals:SetText(format(WHO_FRAME_TOTAL_TEMPLATE, totalCount).."  "..displayedText);
	for i=1, WHOS_TO_DISPLAY, 1 do
		whoIndex = whoOffset + i;
		button = _G["WhoFrameButton"..i];
		button.whoIndex = whoIndex;
		button.tooltip1 = nil;
		button.tooltip2 = nil;
		local info = C_FriendList.GetWhoInfo(whoIndex);
		name = nil;
		if ( info ) then
			name = info.fullName;
			guild = info.fullGuildName;
			level = info.level;
			race = info.raceStr;
			class = info.classStr;
			zone = info.area;
			classFileName = info.filename;
		end
		
		columnTable = { zone, guild, race };

		if ( classFileName ) then
			classTextColor = RAID_CLASS_COLORS[classFileName];
		else
			classTextColor = HIGHLIGHT_FONT_COLOR;
		end
		buttonText = _G["WhoFrameButton"..i.."Name"];
		buttonText:SetText(name);
		local nameTruncated = buttonText:IsTruncated()

		buttonText = _G["WhoFrameButton"..i.."Level"];
		buttonText:SetText(level);
		buttonText = _G["WhoFrameButton"..i.."Class"];
		buttonText:SetText(class);
		buttonText:SetTextColor(classTextColor.r, classTextColor.g, classTextColor.b);
		local variableText = _G["WhoFrameButton"..i.."Variable"];
		variableText:SetText(columnTable[whoSortValue]);

		if (variableText:IsTruncated() or nameTruncated) then
			button.tooltip1 = name;
			button.tooltip2 = columnTable[whoSortValue];
		end

		-- If need scrollbar resize columns
		if ( showScrollBar ) then
			variableText:SetWidth(95);
		else
			variableText:SetWidth(110);
		end

		-- Highlight the correct who
		if ( WhoFrame.selectedWho == whoIndex ) then
			button:LockHighlight();
		else
			button:UnlockHighlight();
		end

		if ( whoIndex > numWhos ) then
			button:Hide();
		else
			button:Show();
		end
	end

	if ( not WhoFrame.selectedWho ) then
		WhoFrameGroupInviteButton:Disable();
		WhoFrameAddFriendButton:Disable();
	else
		WhoFrameGroupInviteButton:Enable();
		WhoFrameAddFriendButton:Enable();
		WhoFrame.selectedName = C_FriendList.GetWhoInfo(WhoFrame.selectedWho).fullName;
	end

	-- If need scrollbar resize columns
	if ( showScrollBar ) then
		WhoFrameColumn_SetWidth(WhoFrameColumnHeader2, 105);
		WhoFrameDropdown:SetWidth(80);
	else
		WhoFrameColumn_SetWidth(WhoFrameColumnHeader2, 120);
		WhoFrameDropdown:SetWidth(95);
	end

	-- ScrollFrame update
	FauxScrollFrame_Update(WhoListScrollFrame, numWhos, WHOS_TO_DISPLAY, FRIENDS_FRAME_WHO_HEIGHT );

	PanelTemplates_SetTab(FriendsFrame, 2);
	ShowUIPanel(FriendsFrame);
end

function WhoFrameColumn_SetWidth(frame, width)
	frame:SetWidth(width);
	local name = frame:GetName().."Middle";
	local middleFrame = _G[name];
	if middleFrame then
		middleFrame:SetWidth(width - 9);
	end
end

function WhoFrameDropdown_OnLoad(self)
	WowStyle1DropdownMixin.OnLoad(self);

	local function IsSelected(sortData)
		return sortData.value == whoSortValue;
	end

	local function SetSelected(sortData)
		whoSortValue = sortData.value;
		C_FriendList.SortWho(sortData.sortType);
			
		WhoList_Update();
	end

	self:SetWidth(101);
	self:SetupMenu(function(dropdown, rootDescription)
		rootDescription:SetTag("MENU_FRIENDS_WHO");

		rootDescription:CreateRadio(ZONE, IsSelected, SetSelected, {value = 1, sortType = "zone"});
		rootDescription:CreateRadio(GUILD, IsSelected, SetSelected, {value = 2, sortType = "guild"});
		rootDescription:CreateRadio(RACE, IsSelected, SetSelected, {value = 3, sortType = "race"});
	end);
end

function WhoFrameDropdown_OnShow(self)
	whoSortValue = 1;
end

function WhoFrameDropdown_OnEnter(self)
	self.TabHighlight:Show();
end

function WhoFrameDropdown_OnLeave(self)
	self.TabHighlight:Hide();
end

function FriendsFrameFriendButton_OnClick(self, button)
	if ( button == "LeftButton" ) then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
		FriendsFrame_SelectFriend(self.buttonType, self.id);
		FriendsList_Update();
		-- if friends of friends frame is being shown, switch list if new selection is another battlenet friend
		if ( FriendsFriendsFrame:IsShown() and self.buttonType == FRIENDS_BUTTON_TYPE_BNET ) then
			local bnetIDAccount = BNGetFriendInfo(self.id);
			if ( bnetIDAccount ~= FriendsFriendsFrame.bnetIDAccount ) then
				FriendsFriendsFrame_Show(bnetIDAccount);
			end
		end
	elseif ( button == "RightButton" ) then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
		if ( self.buttonType == FRIENDS_BUTTON_TYPE_BNET ) then
			-- bnet friend
			local bnetIDAccount, accountName, battleTag, isBattleTag, characterName, bnetIDGameAccount, client, isOnline = BNGetFriendInfo(self.id);
			FriendsFrame_ShowBNDropdown(accountName, isOnline, nil, nil, nil, 1, bnetIDAccount, nil, nil, nil, nil);
		else
			-- wow friend
			local info = C_FriendList.GetFriendInfoByIndex(self.id);
			FriendsFrame_ShowDropdown(info.name, info.connected, nil, nil, nil, 1, nil, nil, nil, nil, nil, info.guid);
		end
	end
end

function FriendsFrame_SelectFriend(friendType, id)
	if ( friendType == FRIENDS_BUTTON_TYPE_WOW ) then
		C_FriendList.SetSelectedFriend(id);
	elseif ( friendType == FRIENDS_BUTTON_TYPE_BNET ) then
		BNSetSelectedFriend(id);
	end
	FriendsFrame.selectedFriendType = friendType;
end

function FriendsFrame_SelectSquelched(ignoreType, index)
	if ( ignoreType == SQUELCH_TYPE_IGNORE ) then
		C_FriendList.SetSelectedIgnore(index);
	elseif ( ignoreType == SQUELCH_TYPE_BLOCK_INVITE ) then
		BNSetSelectedBlock(index);
	end
	FriendsFrame.selectedSquelchType = ignoreType;
end

function FriendsFrameAddFriendButton_OnClick(self)
	local name = GetUnitName("target", true);
	if ( UnitIsPlayer("target") and UnitCanCooperate("player", "target") and not C_FriendList.GetFriendInfo(name) ) then
		C_FriendList.AddFriend(name);
		PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
	else
		local _, battleTag, _, _, _, _, isRIDEnabled = BNGetInfo();
		if ( ( battleTag or isRIDEnabled ) and BNFeaturesEnabledAndConnected() ) then
			AddFriendEntryFrame_Collapse(true);
			AddFriendFrame.editFocus = AddFriendNameEditBox;
			StaticPopupSpecial_Show(AddFriendFrame);
			if ( GetCVarBool("addFriendInfoShown") ) then
				AddFriendFrame_ShowEntry();
			else
				AddFriendFrame_ShowInfo();
			end
		else
			StaticPopup_Show("ADD_FRIEND");
		end
	end
end

function FriendsFrameSendMessageButton_OnClick(self)
	local name;
	if ( FriendsFrame.selectedFriendType == FRIENDS_BUTTON_TYPE_WOW ) then
		name = C_FriendList.GetFriendInfoByIndex(FriendsFrame.selectedFriend).name;
		ChatFrame_SendTell(name);
	elseif ( FriendsFrame.selectedFriendType == FRIENDS_BUTTON_TYPE_BNET ) then
		local bnetIDAccount, tokenizedName = BNGetFriendInfo(FriendsFrame.selectedFriend);
		ChatFrame_SendBNetTell(tokenizedName);
	end
	if ( name ) then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	end
end

function FriendsFrameMuteButton_OnClick(self)
	SetSelectedMute(self:GetID());
	MutedList_Update();
end

function FriendsFrameUnsquelchButton_OnClick(self)
	local selectedSquelchType = FriendsFrame.selectedSquelchType;
	if ( selectedSquelchType == SQUELCH_TYPE_IGNORE ) then
		C_FriendList.DelIgnoreByIndex(C_FriendList.GetSelectedIgnore());
	elseif ( selectedSquelchType == SQUELCH_TYPE_BLOCK_INVITE ) then
		local blockID = BNGetBlockedInfo(BNGetSelectedBlock());
		BNSetBlocked(blockID, false);
	end
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
end

function FriendsFrameWhoButton_OnClick(self, button)
	if ( button == "LeftButton" ) then
		WhoFrame.selectedWho = _G["WhoFrameButton"..self:GetID()].whoIndex;
		WhoFrame.selectedName = _G["WhoFrameButton"..self:GetID().."Name"]:GetText();
		WhoList_Update();
	else
		local name = _G["WhoFrameButton"..self:GetID().."Name"]:GetText();
		FriendsFrame_ShowDropdown(name, 1, nil, nil, nil, nil , nil, nil, nil, nil, nil , nil, _G["WhoFrameButton"..self:GetID()].whoIndex);
	end
end

function FriendsFrame_UnIgnore(button, name)
	if ( not C_FriendList.DelIgnore(name) ) then
		UIErrorsFrame:AddExternalErrorMessage(ERR_IGNORE_NOT_FOUND);
	end
end

function FriendsFrame_UnBlock(button, blockID)
	BNSetBlocked(blockID, false);
end

function FriendsFrame_RemoveFriend()
	if ( FriendsFrame.selectedFriend ) then
		C_FriendList.RemoveFriendByIndex(FriendsFrame.selectedFriend);
		PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
	end
end

function FriendsFrame_SendMessage()
	local name = C_FriendList.GetFriendInfoByIndex(FriendsFrame.selectedFriend).name;
	ChatFrame_SendTell(name);
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
end

function FriendsFrame_GroupInvite()
	local name = C_FriendList.GetFriendInfoByIndex(FriendsFrame.selectedFriend).name;
	InviteToGroup(name);
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
end

function ToggleFriendsFrame(tab)
	if (Kiosk.IsEnabled()) then
		return;
	end

	if ( not tab ) then
		if ( FriendsFrame:IsShown() ) then
			HideUIPanel(FriendsFrame);
		else
			ShowUIPanel(FriendsFrame);
		end
	else
		-- If not in a guild don't do anything when they try to toggle the guild tab
		if ( tab == FRIEND_TAB_GUILD and not IsInGuild() ) then
			return;
		end
		if ( tab == PanelTemplates_GetSelectedTab(FriendsFrame) and FriendsFrame:IsShown() ) then
			HideUIPanel(FriendsFrame);
			return;
		end

		-- If we made it here, show the tab.
		PanelTemplates_SetTab(FriendsFrame, tab);
		if ( FriendsFrame:IsShown() ) then
			FriendsFrame_OnShow();
		else
			ShowUIPanel(FriendsFrame);
		end
	end
end

function OpenFriendsFrame(tab)
	if ( not tab ) then
		ShowUIPanel(FriendsFrame);
	else
		PanelTemplates_SetTab(FriendsFrame, tab);
		if ( FriendsFrame:IsShown() ) then
			FriendsFrame_OnShow();
		else
			ShowUIPanel(FriendsFrame);
		end
	end
end

function WhoFrameEditBox_OnEnterPressed(self)
	C_FriendList.SendWho(self:GetText(), Enum.SocialWhoOrigin.Social);
	self:ClearFocus();
end

function ShowWhoPanel()
	PanelTemplates_SetTab(FriendsFrame, 2);
	if ( FriendsFrame:IsShown() ) then
		FriendsFrame_OnShow();
	else
		ShowUIPanel(FriendsFrame);
	end
end

function ToggleFriendsSubPanel(panelIndex)
	if (Kiosk.IsEnabled()) then
		return;
	end

	local panelShown =
		FriendsFrame:IsShown() and
		PanelTemplates_GetSelectedTab(FriendsFrame) == FRIEND_TAB_FRIENDS and
		FriendsTabHeader.selectedTab == panelIndex;

	if ( panelShown ) then
		HideUIPanel(FriendsFrame);
	else
		PanelTemplates_SetTab(FriendsFrame, FRIEND_TAB_FRIENDS);
		PanelTemplates_SetTab(FriendsTabHeader, panelIndex);
		FriendsFrame_Update();
		ShowUIPanel(FriendsFrame);
	end
end

function ToggleFriendsPanel()
	ToggleFriendsSubPanel(FRIEND_HEADER_TAB_FRIENDS);
end

function ToggleIgnorePanel()
	ToggleFriendsSubPanel(FRIEND_HEADER_TAB_IGNORE);
end

function WhoFrame_GetDefaultWhoCommand()
	local level = UnitLevel("player");
	local minLevel = level-3;
	if ( minLevel <= 0 ) then
		minLevel = 1;
	end
	local maxLevel = min(level + 3, GetMaxPlayerLevel());
	local command = WHO_TAG_ZONE.."\""..GetRealZoneText().."\" "..minLevel.."-"..maxLevel;
	return command;
end

function FriendsFrame_GetLastOnline(timeDifference, isAbsolute)
	if ( not isAbsolute ) then
		timeDifference = time() - timeDifference;
	end
	local year, month, day, hour, minute;

	if ( timeDifference < ONE_MINUTE ) then
		return LASTONLINE_SECS;
	elseif ( timeDifference >= ONE_MINUTE and timeDifference < ONE_HOUR ) then
		return format(LASTONLINE_MINUTES, floor(timeDifference / ONE_MINUTE));
	elseif ( timeDifference >= ONE_HOUR and timeDifference < ONE_DAY ) then
		return format(LASTONLINE_HOURS, floor(timeDifference / ONE_HOUR));
	elseif ( timeDifference >= ONE_DAY and timeDifference < ONE_MONTH ) then
		return format(LASTONLINE_DAYS, floor(timeDifference / ONE_DAY));
	elseif ( timeDifference >= ONE_MONTH and timeDifference < ONE_YEAR ) then
		return format(LASTONLINE_MONTHS, floor(timeDifference / ONE_MONTH));
	else
		return format(LASTONLINE_YEARS, floor(timeDifference / ONE_YEAR));
	end
end


-- Battle.net stuff starts here

function FriendsFrame_CheckBattlenetStatus()
	if GetCurrentRegionName() == "CN" then
		FriendsFrameBattlenetFrame.BroadcastButton:Disable();
		FriendsFrameBattlenetFrame.BroadcastButton:SetAlpha(0);
	end

	if ( BNFeaturesEnabled() ) then
		local frame = FriendsFrameBattlenetFrame;
		if ( BNConnected() ) then
			playerNativeRealmID = GetNativeRealmID();
			playerRealmName = GetRealmName();
			playerFactionGroup = UnitFactionGroup("player");
			FriendsFrameBattlenetFrame_UpdateBroadcast();
			local _, battleTag = BNGetInfo();
			if ( battleTag ) then
				local symbol = string.find(battleTag, "#");
				if ( symbol ) then
					local suffix = string.sub(battleTag, symbol);
					battleTag = string.sub(battleTag, 1, symbol - 1).."|cff416380"..suffix.."|r";
				end
				frame.Tag:SetText(battleTag);
				frame.Tag:Show();
				frame:Show();
				FriendsFrameBroadcastInput:Hide();
			else
				frame:Hide();
				--FriendsFrameBroadcastInput:Show();
				--FriendsFrameBroadcastInput_UpdateDisplay();
			end
			frame.UnavailableLabel:Hide();
			frame.BroadcastButton:Show();
			frame.UnavailableInfoButton:Hide();
			frame.UnavailableInfoFrame:Hide();
		else
			frame:Show();
			FriendsFrameBattlenetFrame_HideSubFrames();
			frame.Tag:Hide();
			frame.UnavailableLabel:Show();
			frame.BroadcastButton:Hide();
			frame.UnavailableInfoButton:Show();
			FriendsFrameBroadcastInput:Hide();
		end
		if ( FriendsFrame:IsShown() ) then
			IgnoreList_Update();
		end
		-- has its own check if it is being shown, after it updates the count on the QuickJoinToastButton
		FriendsList_Update();
	end
end

function FriendsFrame_UpdateFriends()
	local scrollFrame = FriendsFrameFriendsScrollFrame;
	local offset = HybridScrollFrame_GetOffset(scrollFrame);
	local buttons = scrollFrame.buttons;
	local numButtons = #buttons;
	local numFriendButtons = scrollFrame.numFriendListEntries;

	local usedHeight = 0;

	scrollFrame.dividerPool:ReleaseAll();
	scrollFrame.invitePool:ReleaseAll();
	scrollFrame.PendingInvitesHeaderButton:Hide();
	for i = 1, numButtons do
		local button = buttons[i];
		local index = offset + i;
		if ( index <= numFriendButtons ) then
			button.index = index;
			local height = FriendsFrame_UpdateFriendButton(button);
			button:SetHeight(height);
			usedHeight = usedHeight + height;
		else
			button.index = nil;
			button:Hide();
		end
	end
	HybridScrollFrame_Update(scrollFrame, scrollFrame.totalFriendListEntriesHeight, usedHeight);
end

local function ShowRichPresenceOnly(client, wowProjectID, faction, realmID)
	if (client ~= BNET_CLIENT_WOW) or (wowProjectID ~= WOW_PROJECT_ID) then
		-- If they are not in wow or in a different version of wow, always show rich presence only
		return true;
	elseif ((faction ~= playerFactionGroup) or (realmID ~= playerNativeRealmID)) then
		-- If we are both in wow classic and our factions or realms don't match, show rich presence only
		return true;
	else
		-- Otherwise show more detailed info about them
		return false;
	end;
end

function FriendsFrame_UpdateFriendButton(button)
	local index = button.index;
	button.buttonType = FriendListEntries[index].buttonType;
	button.id = FriendListEntries[index].id;
	local height = FRIENDS_BUTTON_HEIGHTS[button.buttonType];
	local nameText, nameColor, infoText;
	local hasTravelPassButton = false;
	if ( button.buttonType == FRIENDS_BUTTON_TYPE_WOW ) then
		local info = C_FriendList.GetFriendInfoByIndex(FriendListEntries[index].id);
		if ( info.connected ) then
			button.background:SetColorTexture(FRIENDS_WOW_BACKGROUND_COLOR.r, FRIENDS_WOW_BACKGROUND_COLOR.g, FRIENDS_WOW_BACKGROUND_COLOR.b, FRIENDS_WOW_BACKGROUND_COLOR.a);
			if ( info.afk ) then
				button.status:SetTexture(FRIENDS_TEXTURE_AFK);
			elseif ( info.dnd ) then
				button.status:SetTexture(FRIENDS_TEXTURE_DND);
			else
				button.status:SetTexture(FRIENDS_TEXTURE_ONLINE);
			end
			nameText = info.name..", "..format(FRIENDS_LEVEL_TEMPLATE, info.level, info.className);
			nameColor = FRIENDS_WOW_NAME_COLOR;
		else
			button.background:SetColorTexture(FRIENDS_OFFLINE_BACKGROUND_COLOR.r, FRIENDS_OFFLINE_BACKGROUND_COLOR.g, FRIENDS_OFFLINE_BACKGROUND_COLOR.b, FRIENDS_OFFLINE_BACKGROUND_COLOR.a);
			button.status:SetTexture(FRIENDS_TEXTURE_OFFLINE);
			nameText = info.name;
			nameColor = FRIENDS_GRAY_COLOR;
		end
		infoText = info.area;
		button.gameIcon:Hide();
		button.summonButton:ClearAllPoints();
		button.summonButton:SetPoint("TOPRIGHT", button, "TOPRIGHT", 1, -1);
		FriendsFrame_SummonButton_Update(button.summonButton);
	elseif ( button.buttonType == FRIENDS_BUTTON_TYPE_BNET ) then
		local bnetIDAccount, accountName, battleTag, isBattleTag, characterName, bnetIDGameAccount, client, isOnline, lastOnline, isBnetAFK, isBnetDND, messageText, noteText, isRIDFriend, messageTime, canSoR = BNGetFriendInfo(FriendListEntries[index].id);
		-- set up player name and character name
		if ( accountName ) then
			nameText = accountName;
			if ( isOnline ) then
				characterName = BNet_GetValidatedCharacterName(characterName, battleTag, client);
			end
		else
			nameText = UNKNOWN;
		end

		-- append character name
		if ( characterName ) then
			if ( client == BNET_CLIENT_WOW and CanCooperateWithGameAccount(bnetIDGameAccount) ) then
				nameText = nameText.." "..FRIENDS_WOW_NAME_COLOR_CODE.."("..characterName..")"..FONT_COLOR_CODE_CLOSE;
			else
				if ( ENABLE_COLORBLIND_MODE == "1" ) then
					characterName = characterName..CANNOT_COOPERATE_LABEL;
				end
				nameText = nameText.." "..FRIENDS_OTHER_NAME_COLOR_CODE.."("..characterName..")"..FONT_COLOR_CODE_CLOSE;
			end
		end

		if ( isOnline ) then
			local gameAccountInfo = C_BattleNet.GetGameAccountInfoByID(bnetIDGameAccount);
			button.background:SetColorTexture(FRIENDS_BNET_BACKGROUND_COLOR.r, FRIENDS_BNET_BACKGROUND_COLOR.g, FRIENDS_BNET_BACKGROUND_COLOR.b, FRIENDS_BNET_BACKGROUND_COLOR.a);
			if(gameAccountInfo) then
				if ( isBnetAFK or gameAccountInfo.isGameAFK ) then
					button.status:SetTexture(FRIENDS_TEXTURE_AFK);
				elseif ( isBnetDND or gameAccountInfo.isGameBusy ) then
					button.status:SetTexture(FRIENDS_TEXTURE_DND);
				else
					button.status:SetTexture(FRIENDS_TEXTURE_ONLINE);
				end

				if ShowRichPresenceOnly(client, gameAccountInfo.wowProjectID, gameAccountInfo.factionName, gameAccountInfo.realmID) then
					infoText = gameAccountInfo.richPresence;
				else
					if ( not gameAccountInfo.areaName or gameAccountInfo.areaName == "" ) then
						infoText = UNKNOWN;
					else
						infoText = gameAccountInfo.areaName;
					end
				end
			end
			
			C_Texture.SetTitleIconTexture(button.gameIcon, client, Enum.TitleIconVersion.Medium);

			local fadeIcon = (client == BNET_CLIENT_WOW) and (gameAccountInfo.wowProjectID ~= WOW_PROJECT_ID);
			if fadeIcon then
				button.gameIcon:SetAlpha(0.6);
			else
				button.gameIcon:SetAlpha(1);
			end

			nameColor = FRIENDS_BNET_NAME_COLOR;

			--Note - this logic should match the logic in FriendsFrame_ShouldShowSummonButton

			local shouldShowSummonButton = FriendsFrame_ShouldShowSummonButton(button.summonButton);
			button.gameIcon:SetShown(not shouldShowSummonButton);

			-- travel pass
			hasTravelPassButton = true;
			local restriction = FriendsFrame_GetInviteRestriction(button.id);
			if ( restriction == INVITE_RESTRICTION_NONE ) then
				button.travelPassButton:Enable();
			else
				button.travelPassButton:Disable();
			end
		else
			button.background:SetColorTexture(FRIENDS_OFFLINE_BACKGROUND_COLOR.r, FRIENDS_OFFLINE_BACKGROUND_COLOR.g, FRIENDS_OFFLINE_BACKGROUND_COLOR.b, FRIENDS_OFFLINE_BACKGROUND_COLOR.a);
			button.status:SetTexture(FRIENDS_TEXTURE_OFFLINE);
			nameColor = FRIENDS_GRAY_COLOR;
			button.gameIcon:Hide();
			if ( not lastOnline or lastOnline == 0 or time() - lastOnline >= ONE_YEAR ) then
				infoText = FRIENDS_LIST_OFFLINE;
			else
				infoText = string.format(BNET_LAST_ONLINE_TIME, FriendsFrame_GetLastOnline(lastOnline));
			end
		end
		button.summonButton:ClearAllPoints();
		button.summonButton:SetPoint("CENTER", button.gameIcon, "CENTER", 1, 0);
		FriendsFrame_SummonButton_Update(button.summonButton);
	elseif ( button.buttonType == FRIENDS_BUTTON_TYPE_DIVIDER ) then
		local scrollFrame = FriendsFrameFriendsScrollFrame;
		local divider = scrollFrame.dividerPool:Acquire();
		divider:SetParent(scrollFrame.ScrollChild);
		divider:SetAllPoints(button);
		divider:Show();
		nameText = nil;
	elseif ( button.buttonType == FRIENDS_BUTTON_TYPE_INVITE_HEADER ) then
		local header = FriendsFrameFriendsScrollFrame.PendingInvitesHeaderButton;
		header:SetPoint("TOPLEFT", button, 1, 0);
		header:Show();
		header:SetFormattedText(FRIEND_REQUESTS, BNGetNumFriendInvites());
		local collapsed = GetCVarBool("friendInvitesCollapsed");
		if ( collapsed ) then
			header.DownArrow:Hide();
			header.RightArrow:Show();
		else
			header.DownArrow:Show();
			header.RightArrow:Hide();
		end
		nameText = nil;
	elseif ( button.buttonType == FRIENDS_BUTTON_TYPE_INVITE ) then
		local scrollFrame = FriendsFrameFriendsScrollFrame;
		local invite = scrollFrame.invitePool:Acquire();
		invite:SetParent(scrollFrame.ScrollChild);
		invite:SetAllPoints(button);
		invite:Show();
		local inviteID, accountName = BNGetFriendInviteInfo(button.id);
		invite.Name:SetText(accountName);
		invite.inviteID = inviteID;
		invite.inviteIndex = button.id;
		nameText = nil;
	end
	-- travel pass?
	if ( hasTravelPassButton ) then
		button.travelPassButton:Show();
	else
		button.travelPassButton:Hide();
	end
	-- selection
	if ( FriendsFrame.selectedFriendType == FriendListEntries[index].buttonType and FriendsFrame.selectedFriend == FriendListEntries[index].id ) then
		button:LockHighlight();
	else
		button:UnlockHighlight();
	end
	-- finish setting up button if it's not a header
	if ( nameText ) then
		button.name:SetText(nameText);
		button.name:SetTextColor(nameColor.r, nameColor.g, nameColor.b);
		button.info:SetText(infoText);
		button:Show();
	else
		button:Hide();
	end
	-- update the tooltip if hovering over a button
	if ( FriendsTooltip.button == button ) then
		FriendsFrameTooltip_Show(button);
	end
	if ( button:IsMouseMotionFocus() ) then
		FriendsFrameTooltip_Show(button);
	end
	return height;
end

function FriendsFrameBroadcastInput_OnEnterPressed(self)
	local broadcastText = self:GetText()
	BNSetCustomMessage(broadcastText);
	FriendsFrameBroadcastInput_UpdateDisplay(self, broadcastText);
end

function FriendsFrameBroadcastInput_OnEscapePressed(self)
	FriendsFrameBroadcastInput_UpdateDisplay(self);
end

function FriendsFrameBroadcastInput_OnClearPressed(self)
	BNSetCustomMessage("");
	FriendsFrameBroadcastInput_UpdateDisplay(nil, "");
end

function FriendsFrameBroadcastInput_UpdateDisplay(self, broadcastText)
	local _;
	self = self or FriendsFrameBroadcastInput;
	if ( not broadcastText ) then
		_, _, _, broadcastText = BNGetInfo();
		broadcastText = broadcastText or "";
	end
	self:ClearFocus();
	self:SetText(broadcastText);
	if ( broadcastText ~= "" ) then
		self.icon:SetAlpha(1);
		self:SetCursorPosition(0);
		self.clear:Show();
		self:SetTextInsets(0, 18, 0, 0);
	else
		self.icon:SetAlpha(0.35);
		self.clear:Hide();
		self:SetTextInsets(0, 10, 0, 0);
	end
end

function FriendsFrameBattlenetFrame_ShowBroadcastFrame()
	FriendsFrameBattlenetFrame.BroadcastFrame:Show();
	FriendsFrameBattlenetFrame.BroadcastFrame.ScrollFrame.EditBox:SetFocus();
	FriendsFrameBattlenetFrame.BroadcastButton:SetNormalTexture("Interface\\FriendsFrame\\broadcast-hover");
	FriendsFrameBattlenetFrame.BroadcastButton:SetPushedTexture("Interface\\FriendsFrame\\broadcast-pressed-hover");
end

function FriendsFrameBattlenetFrame_HideBroadcastFrame()
	FriendsFrameBattlenetFrame.BroadcastFrame:Hide();
	FriendsFrameBattlenetFrame.BroadcastButton:SetNormalTexture("Interface\\FriendsFrame\\broadcast-normal");
	FriendsFrameBattlenetFrame.BroadcastButton:SetPushedTexture("Interface\\FriendsFrame\\broadcast-press");
end

function FriendsFrameBattlenetFrame_HideSubFrames()
	FriendsFrameBattlenetFrame_HideBroadcastFrame();
	FriendsFrameBattlenetFrame.UnavailableInfoFrame:Hide();
end

function FriendsFrameBattlenetFrame_UpdateBroadcast(newBroadcastText)
	local _, battleTag, _, broadcastText = BNGetInfo();
	broadcastText = newBroadcastText or broadcastText or "";

	if ( battleTag ) then
		local editBox = FriendsFrameBattlenetFrame.BroadcastFrame.ScrollFrame.EditBox;
		editBox:SetText(broadcastText);
		if ( broadcastText == "" ) then
			editBox.PromptText:Show();
		else
			editBox.PromptText:Hide();
		end
	else
		FriendsFrameBroadcastInput_UpdateDisplay(nil, broadcastText);
	end
end

function FriendsFrameBattlenetFrame_SetBroadcast()
	local newBroadcastText = FriendsFrameBattlenetFrame.BroadcastFrame.ScrollFrame.EditBox:GetText();
	local _, _, _, broadcastText = BNGetInfo();
	if ( newBroadcastText ~= broadcastText ) then
		BNSetCustomMessage(newBroadcastText);
	end
	FriendsFrameBattlenetFrame_HideBroadcastFrame();
end

function FriendsFrameTooltip_Show(self)
	if ( self.buttonType == FRIENDS_BUTTON_TYPE_DIVIDER ) then
		return;
	end
	local anchor, text;
	local FRIENDS_TOOLTIP_WOW_INFO_TEMPLATE = NORMAL_FONT_COLOR_CODE..FRIENDS_LIST_ZONE.."|r%1$s|n"..NORMAL_FONT_COLOR_CODE..FRIENDS_LIST_REALM.."|r%2$s";
	local numGameAccounts = 0;
	local tooltip = FriendsTooltip;
	local isOnline = false;
	local battleTag = "";
	tooltip.height = 0;
	tooltip.maxWidth = 0;

	if ( self.buttonType == FRIENDS_BUTTON_TYPE_BNET ) then
		local nameText;
		local bnetIDAccount, accountName, isBattleTag, _characterName, bnetIDGameAccount, _client, lastOnline, isAFK, isDND, broadcastText, noteText, isFriend, broadcastTime;
		bnetIDAccount, accountName, battleTag, isBattleTag, _characterName, bnetIDGameAccount, _client, isOnline, lastOnline, isAFK, isDND, broadcastText, noteText, isFriend, broadcastTime = BNGetFriendInfo(self.id);
		-- account name
		if ( accountName ) then
			nameText = accountName;
		else
			nameText = UNKNOWN;
		end
		anchor = FriendsFrameTooltip_SetLine(FriendsTooltipHeader, nil, nameText);
		-- game account 1
		if ( bnetIDGameAccount ) then
			local hasFocus, characterName, client, realmName, realmID, faction, race, class, _, zoneName, level, gameText, _, _, _, _, _, _, _, _, wowProjectID, realmDisplayName = BNGetGameAccountInfo(bnetIDGameAccount);
			level = level or "";
			race = race or "";
			class = class or "";
			
			if ShowRichPresenceOnly(client, wowProjectID, faction, realmID) then
				if ( isOnline ) then
					characterName = BNet_GetValidatedCharacterName(characterName, battleTag, client) or "";
				end
				FriendsFrameTooltip_SetLine(FriendsTooltipGameAccount1Name, nil, characterName);
				anchor = FriendsFrameTooltip_SetLine(FriendsTooltipGameAccount1Info, nil, gameText, -4);
			else
				if ( CanCooperateWithGameAccount(bnetIDGameAccount) ) then
					text = string.format(FRIENDS_TOOLTIP_WOW_TOON_TEMPLATE, characterName, level, race, class);
				else
					text = string.format(FRIENDS_TOOLTIP_WOW_TOON_TEMPLATE, characterName..CANNOT_COOPERATE_LABEL, level, race, class);
				end
				FriendsFrameTooltip_SetLine(FriendsTooltipGameAccount1Name, nil, text);
				anchor = FriendsFrameTooltip_SetLine(FriendsTooltipGameAccount1Info, nil, string.format(FRIENDS_TOOLTIP_WOW_INFO_TEMPLATE, zoneName, realmDisplayName), -4);
			end
		else
			FriendsTooltipGameAccount1Info:Hide();
			FriendsTooltipGameAccount1Name:Hide();
		end
		-- note
		if ( noteText and noteText ~= "" ) then
			FriendsTooltipNoteIcon:Show();
			anchor = FriendsFrameTooltip_SetLine(FriendsTooltipNoteText, anchor, noteText, -8);
		else
			FriendsTooltipNoteIcon:Hide();
			FriendsTooltipNoteText:Hide();
		end
		-- broadcast
		if ( broadcastText and broadcastText ~= "" ) then
			FriendsTooltipBroadcastIcon:Show();
			if ( time() - broadcastTime < ONE_YEAR ) then
				broadcastText = broadcastText.."|n"..FRIENDS_BROADCAST_TIME_COLOR_CODE..string.format(BNET_BROADCAST_SENT_TIME, FriendsFrame_GetLastOnline(broadcastTime)..FONT_COLOR_CODE_CLOSE);
			end
			anchor = FriendsFrameTooltip_SetLine(FriendsTooltipBroadcastText, anchor, broadcastText, -8);
			FriendsTooltip.hasBroadcast = true;
		else
			FriendsTooltipBroadcastIcon:Hide();
			FriendsTooltipBroadcastText:Hide();
			FriendsTooltip.hasBroadcast = nil;
		end
		if ( isOnline ) then
			FriendsTooltipHeader:SetTextColor(FRIENDS_BNET_NAME_COLOR.r, FRIENDS_BNET_NAME_COLOR.g, FRIENDS_BNET_NAME_COLOR.b);
			FriendsTooltipLastOnline:Hide();
			numGameAccounts = BNGetNumFriendGameAccounts(self.id);
		else
			FriendsTooltipHeader:SetTextColor(FRIENDS_GRAY_COLOR.r, FRIENDS_GRAY_COLOR.g, FRIENDS_GRAY_COLOR.b);
			if ( not lastOnline or lastOnline == 0 or time() - lastOnline >= ONE_YEAR ) then
				text = FRIENDS_LIST_OFFLINE;
			else
				text = string.format(BNET_LAST_ONLINE_TIME, FriendsFrame_GetLastOnline(lastOnline));
			end
			anchor = FriendsFrameTooltip_SetLine(FriendsTooltipLastOnline, anchor, text, -4);
		end
	elseif ( self.buttonType == FRIENDS_BUTTON_TYPE_WOW ) then
		local info = C_FriendList.GetFriendInfoByIndex(self.id);
		anchor = FriendsFrameTooltip_SetLine(FriendsTooltipHeader, nil, info.name);
		if ( info.connected ) then
			FriendsTooltipHeader:SetTextColor(FRIENDS_WOW_NAME_COLOR.r, FRIENDS_WOW_NAME_COLOR.g, FRIENDS_WOW_NAME_COLOR.b);
			FriendsFrameTooltip_SetLine(FriendsTooltipGameAccount1Name, nil, string.format(FRIENDS_LEVEL_TEMPLATE, info.level, info.className));
			anchor = FriendsFrameTooltip_SetLine(FriendsTooltipGameAccount1Info, nil, info.area);
		else
			FriendsTooltipHeader:SetTextColor(FRIENDS_GRAY_COLOR.r, FRIENDS_GRAY_COLOR.g, FRIENDS_GRAY_COLOR.b);
			FriendsTooltipGameAccount1Name:Hide();
			FriendsTooltipGameAccount1Info:Hide();
		end
		if ( info.notes ) then
			FriendsTooltipNoteIcon:Show();
			anchor = FriendsFrameTooltip_SetLine(FriendsTooltipNoteText, anchor, info.notes, -8);
		else
			FriendsTooltipNoteIcon:Hide();
			FriendsTooltipNoteText:Hide();
		end
		FriendsTooltipBroadcastIcon:Hide();
		FriendsTooltipBroadcastText:Hide();
		FriendsTooltipLastOnline:Hide();
	end

	-- other game accounts
	local gameAccountIndex = 1;
	local characterNameString;
	local gameAccountInfoString;
	if ( numGameAccounts > 1 ) then
		local headerSet = false;
		for i = 1, numGameAccounts do
			local hasFocus, characterName, client, realmName, realmID, faction, race, class, _, zoneName, level, gameText, _, _, _, _, _, _, _, _, wowProjectID = BNGetFriendGameAccountInfo(self.id, i);
			-- the focused game account is already at the top of the tooltip
			if ( not hasFocus and client ~= BNET_CLIENT_APP and client ~= BNET_CLIENT_CLNT ) then
				if ( not headerSet ) then
					FriendsFrameTooltip_SetLine(FriendsTooltipOtherGameAccounts, anchor, nil, -8);
					headerSet = true;
				end
				gameAccountIndex = gameAccountIndex + 1;
				if ( gameAccountIndex > FRIENDS_TOOLTIP_MAX_GAME_ACCOUNTS ) then
					break;
				end
				characterNameString = _G["FriendsTooltipGameAccount"..gameAccountIndex.."Name"];
				gameAccountInfoString = _G["FriendsTooltipGameAccount"..gameAccountIndex.."Info"];
				text = BNet_GetClientEmbeddedAtlas(client, 18).." ";
				if ( client == BNET_CLIENT_WOW and wowProjectID == WOW_PROJECT_ID ) then
					if ( realmName == playerRealmName and faction == playerFactionGroup ) then
						text = text..string.format(FRIENDS_TOOLTIP_WOW_TOON_TEMPLATE, characterName, level, race, class);
					else
						text = text..string.format(FRIENDS_TOOLTIP_WOW_TOON_TEMPLATE, characterName..CANNOT_COOPERATE_LABEL, level, race, class);
					end
					gameText = zoneName;
				else
					if ( isOnline ) then
						characterName = BNet_GetValidatedCharacterName(characterName, battleTag, client) or "";
					end
					text = text..characterName;
				end
				FriendsFrameTooltip_SetLine(characterNameString, nil, text);
				FriendsFrameTooltip_SetLine(gameAccountInfoString, nil, gameText);
			end
		end
		if ( not headerSet ) then
			FriendsTooltipOtherGameAccounts:Hide();
		end
	else
		FriendsTooltipOtherGameAccounts:Hide();
	end
	for i = gameAccountIndex + 1, FRIENDS_TOOLTIP_MAX_GAME_ACCOUNTS do
		characterNameString = _G["FriendsTooltipGameAccount"..i.."Name"];
		gameAccountInfoString = _G["FriendsTooltipGameAccount"..i.."Info"];
		characterNameString:Hide();
		gameAccountInfoString:Hide();
	end
	if ( numGameAccounts > FRIENDS_TOOLTIP_MAX_GAME_ACCOUNTS ) then
		FriendsFrameTooltip_SetLine(FriendsTooltipGameAccountMany, nil, string.format(FRIENDS_TOOLTIP_TOO_MANY_CHARACTERS, numGameAccounts - FRIENDS_TOOLTIP_MAX_GAME_ACCOUNTS), 0);
	else
		FriendsTooltipGameAccountMany:Hide();
	end

	tooltip.button = self;
	tooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 36, 0);
	tooltip:SetHeight(tooltip.height + FRIENDS_TOOLTIP_MARGIN_WIDTH);
	tooltip:SetWidth(min(FRIENDS_TOOLTIP_MAX_WIDTH, tooltip.maxWidth + FRIENDS_TOOLTIP_MARGIN_WIDTH));
	tooltip:Show();
end

function FriendsFrameTooltip_SetLine(line, anchor, text, yOffset)
	local tooltip = FriendsTooltip;
	local top = 0;
	local left = FRIENDS_TOOLTIP_MAX_WIDTH - FRIENDS_TOOLTIP_MARGIN_WIDTH - line:GetWidth();

	if ( text ) then
		line:SetText(text);
	end
	if ( anchor ) then
		top = yOffset or 0;
		line:SetPoint("TOP", anchor, "BOTTOM", 0, top);
	else
		local point, _, _, _, y = line:GetPoint(1);
		if ( point == "TOP" or point == "TOPLEFT" ) then
			top = y;
		end
	end
	line:Show();
	tooltip.height = tooltip.height + line:GetHeight() - top;
	tooltip.maxWidth = max(tooltip.maxWidth, line:GetStringWidth() + left);
	return line;
end

function AddFriendFrame_OnShow()
	local factionGroup = UnitFactionGroup("player");
	if ( factionGroup and factionGroup ~= "Neutral" ) then
		local textureFile = "Interface\\FriendsFrame\\PlusManz-"..factionGroup;
		AddFriendInfoFrameFactionIcon:SetTexture(textureFile);
		AddFriendInfoFrameFactionIcon:Show();
		AddFriendEntryFrameRightIcon:SetTexture(textureFile);
		AddFriendEntryFrameRightIcon:Show();
		AddFriendInfoFrameFactionIcon:Show();
	else
		AddFriendInfoFrameFactionIcon:Hide();
	end
end

function AddFriendFrame_ShowInfo()
	AddFriendFrame:SetWidth(AddFriendInfoFrame:GetWidth());
	AddFriendFrame:SetHeight(AddFriendInfoFrame:GetHeight());
	AddFriendInfoFrame:Show();
	AddFriendEntryFrame:Hide();
	PlaySound(SOUNDKIT.IG_MAINMENU_OPEN);
end

function AddFriendFrame_ShowEntry()
	AddFriendFrame:SetWidth(AddFriendEntryFrame:GetWidth());
	AddFriendFrame:SetHeight(AddFriendEntryFrame:GetHeight());
	AddFriendInfoFrame:Hide();
	AddFriendEntryFrame:Show();
	if ( BNFeaturesEnabledAndConnected() ) then
		AddFriendFrame.BNconnected = true;
		AddFriendEntryFrameLeftTitle:SetAlpha(1);
		AddFriendEntryFrameLeftDescription:SetTextColor(1, 1, 1);
		AddFriendEntryFrameLeftIcon:SetVertexColor(1, 1, 1);
		AddFriendEntryFrameLeftFriend:SetVertexColor(1, 1, 1);
		local _, battleTag, _, _, _, _, isRIDEnabled = BNGetInfo();
		if ( battleTag and isRIDEnabled ) then
			AddFriendEntryFrameLeftTitle:SetText(REAL_ID);
			AddFriendEntryFrameLeftDescription:SetText(REALID_BATTLETAG_FRIEND_LABEL);
			AddFriendNameEditBoxFill:SetText(ENTER_NAME_OR_BATTLETAG_OR_EMAIL);
		elseif ( isRIDEnabled ) then
			AddFriendEntryFrameLeftTitle:SetText(REAL_ID);
			AddFriendEntryFrameLeftDescription:SetText(REALID_FRIEND_LABEL);
			AddFriendNameEditBoxFill:SetText(ENTER_NAME_OR_EMAIL);
		elseif ( battleTag ) then
			AddFriendEntryFrameLeftTitle:SetText(BATTLETAG);
			AddFriendEntryFrameLeftDescription:SetText(BATTLETAG_FRIEND_LABEL);
			AddFriendNameEditBoxFill:SetText(ENTER_NAME_OR_BATTLETAG);
		end
	else
		AddFriendFrame.BNconnected = nil;
		AddFriendEntryFrameLeftTitle:SetAlpha(0.35);
		AddFriendEntryFrameLeftDescription:SetText(BATTLENET_UNAVAILABLE);
		AddFriendEntryFrameLeftDescription:SetTextColor(1, 0, 0);
		AddFriendEntryFrameLeftIcon:SetVertexColor(.4, .4, .4);
		AddFriendEntryFrameLeftFriend:SetVertexColor(.4, .4, .4);
	end
	if ( AddFriendFrame.editFocus ) then
		AddFriendFrame.editFocus:SetFocus();
	end
	PlaySound(SOUNDKIT.IG_MAINMENU_OPEN);
end

function AddFriendNameEditBox_OnTextChanged(self, userInput)
	if ( not AutoCompleteEditBox_OnTextChanged(self, userInput) ) then
		local text = self:GetText();
		if ( text ~= "" ) then
			AddFriendNameEditBoxFill:Hide();
			if ( AddFriendFrame.BNconnected ) then
				if ( AddFriendFrame_IsValidBattlenetName(text) ) then
					AddFriendEntryFrame_Expand();
				else
					AddFriendEntryFrame_Collapse();
				end
			end
			AddFriendEntryFrameAcceptButton:Enable();
		else
			AddFriendEntryFrame_Collapse();
			AddFriendNameEditBoxFill:Show();
			AddFriendEntryFrameAcceptButton:Disable();
		end
	end
end

function AddFriendEntryFrame_Expand()
--[[
	AddFriendEntryFrame:SetHeight(ADDFRIENDFRAME_BNETHEIGHT);
	AddFriendFrame:SetHeight(ADDFRIENDFRAME_BNETHEIGHT);
	AddFriendNoteFrame:Show();
	AddFriendEntryFrameAcceptButton:SetText(SEND_REQUEST);
	AddFriendEntryFrameRightTitle:SetAlpha(0.35);
	AddFriendEntryFrameRightDescription:SetAlpha(0.35);
	AddFriendEntryFrameRightIcon:SetVertexColor(.4, .4, .4);
	AddFriendEntryFrameRightFriend:SetVertexColor(.4, .4, .4);
	AddFriendEntryFrameLeftIcon:SetAlpha(1);
	AddFriendEntryFrameOrLabel:SetVertexColor(.3, .3, .3);
--]]
end

function AddFriendEntryFrame_Collapse(clearText)
	AddFriendEntryFrame:SetHeight(ADDFRIENDFRAME_WOWHEIGHT);
	AddFriendFrame:SetHeight(ADDFRIENDFRAME_WOWHEIGHT);
	AddFriendNoteFrame:Hide();
	AddFriendEntryFrameAcceptButton:SetText(ADD_FRIEND);
	AddFriendEntryFrameRightTitle:SetAlpha(1);
	AddFriendEntryFrameRightDescription:SetAlpha(1);
	AddFriendEntryFrameRightIcon:SetVertexColor(1, 1, 1);
	AddFriendEntryFrameRightFriend:SetVertexColor(1, 1, 1);
	AddFriendEntryFrameLeftIcon:SetAlpha(0.5);
	if ( AddFriendFrame.BNconnected ) then
		AddFriendEntryFrameOrLabel:SetVertexColor(1, 1, 1);
	else
		AddFriendEntryFrameOrLabel:SetVertexColor(0.3, 0.3, 0.3);
	end
	if ( clearText ) then
		AddFriendNameEditBox:SetText("");
		AddFriendNoteEditBox:SetText("");
	end
end

function AddFriendFrame_Accept()
	local name = AddFriendNameEditBox:GetText();
	if ( AddFriendFrame_IsValidBattlenetName(name) and AddFriendFrame.BNconnected ) then
		BNSendFriendInvite(name, AddFriendNoteEditBox:GetText());
	else
		C_FriendList.AddFriend(name);
	end
	StaticPopupSpecial_Hide(AddFriendFrame);
end

function AddFriendFrame_IsValidBattlenetName(text)
	local _, battleTag, _, _, _, _, isRIDEnabled = BNGetInfo();
	if ( isRIDEnabled and string.find(text, "@") ) then
		return true;
	end
	if ( battleTag and string.find(text, "#") ) then
		return true;
	end
	return false;
end

function FriendsFriendsList_Update()
	if ( FriendsFriendsWaitFrame:IsShown() ) then
		return;
	end

	local friendsButton, friendsIndex;
	local showMutual, showPotential;
	local view = FriendsFriendsFrame.view;
	local selection = FriendsFriendsFrame.selection;
	local requested = FriendsFriendsFrame.requested;
	local bnetIDAccount = FriendsFriendsFrame.bnetIDAccount;
	local numFriendsFriends = 0;
	local numMutual, numPotential = BNGetNumFOF(bnetIDAccount);
	local offset = FauxScrollFrame_GetOffset(FriendsFriendsScrollFrame);
	local haveSelection;
	if ( view == FRIENDS_FRIENDS_POTENTIAL or view == FRIENDS_FRIENDS_ALL ) then
		showPotential = true;
		numFriendsFriends = numFriendsFriends + numPotential;
	end
	if ( view == FRIENDS_FRIENDS_MUTUAL or view == FRIENDS_FRIENDS_ALL ) then
		showMutual = true;
		numFriendsFriends = numFriendsFriends + numMutual;
	end
	for i = 1, FRIENDS_FRIENDS_TO_DISPLAY, 1 do
		friendsIndex = i + offset;
		friendsButton = _G["FriendsFriendsButton"..i];
		if ( friendsIndex > numFriendsFriends ) then
			friendsButton:Hide();
		else
			local friendID, accountName, isMutual = BNGetFOFInfo(showMutual, showPotential, friendsIndex);
			if ( isMutual ) then
				friendsButton:Disable();
				if ( view ~= FRIENDS_FRIENDS_MUTUAL ) then
					friendsButton.name:SetText(accountName.." "..HIGHLIGHT_FONT_COLOR_CODE..FRIENDS_FRIENDS_MUTUAL_TEXT..FONT_COLOR_CODE_CLOSE);
				else
					friendsButton.name:SetText(accountName);
				end
				friendsButton.name:SetTextColor(GRAY_FONT_COLOR	.r, GRAY_FONT_COLOR	.g, GRAY_FONT_COLOR	.b);
			elseif ( requested[friendID] ) then
				friendsButton.name:SetText(accountName.." "..HIGHLIGHT_FONT_COLOR_CODE..FRIENDS_FRIENDS_REQUESTED_TEXT..FONT_COLOR_CODE_CLOSE);
				friendsButton:Disable();
				friendsButton.name:SetTextColor(GRAY_FONT_COLOR	.r, GRAY_FONT_COLOR	.g, GRAY_FONT_COLOR	.b);
			else
				friendsButton.name:SetText(accountName);
				friendsButton:Enable();
				friendsButton.name:SetTextColor(BATTLENET_FONT_COLOR.r, BATTLENET_FONT_COLOR.g, BATTLENET_FONT_COLOR.b);
				if ( selection == friendID ) then
					haveSelection = true;
					friendsButton:LockHighlight();
				else
					friendsButton:UnlockHighlight();
				end
			end
			friendsButton.friendID = friendID;
			friendsButton:Show();
		end
	end
	if ( haveSelection ) then
		FriendsFriendsSendRequestButton:Enable();
	else
		FriendsFriendsSendRequestButton:Disable();
	end
	FauxScrollFrame_Update(FriendsFriendsScrollFrame, numFriendsFriends, FRIENDS_FRIENDS_TO_DISPLAY, FRIENDS_FRAME_FRIENDS_FRIENDS_HEIGHT);
end

function FriendsFriendsButton_OnClick(self)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	FriendsFriendsFrame.selection = self.friendID;
	FriendsFriendsList_Update();
end

function FriendsFrameIgnoreButton_OnClick(self)
	FriendsFrame_SelectSquelched(self.type, self.index);
	IgnoreList_Update();
end

function FriendsFriendsFrame_SendRequest()
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
	FriendsFriendsFrame.requested[FriendsFriendsFrame.selection] = true;
	BNSendFriendInviteByID(FriendsFriendsFrame.selection);
	FriendsFriendsFrame_Reset();
	FriendsFriendsList_Update();
end

function FriendsFriendsFrame_Close()
	StaticPopupSpecial_Hide(FriendsFriendsFrame);
end

FriendsFriendsFrameMixin = {};

function FriendsFriendsFrameMixin:OnLoad()
	self:RegisterEvent("BN_REQUEST_FOF_SUCCEEDED");
	self:RegisterEvent("BN_DISCONNECTED");
	self.requested = {};
	
	self.FriendsDropdown:SetWidth(140);
end

function FriendsFriendsFrameMixin:OnShow()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPEN);

	local function IsSelected(value)
		return value == FriendsFriendsFrame.view;
	end
	
	local function SetSelected(value)
		FriendsFriendsFrame.view = value;
		FriendsFriendsList_Update();
	end;

	self.FriendsDropdown:SetupMenu(function(dropdown, rootDescription)
		rootDescription:SetTag("MENU_FRIENDS_FRIENDS");

		rootDescription:CreateRadio(FRIENDS_FRIENDS_CHOICE_EVERYONE, IsSelected, SetSelected, FRIENDS_FRIENDS_ALL);
		rootDescription:CreateRadio(FRIENDS_FRIENDS_CHOICE_POTENTIAL, IsSelected, SetSelected, FRIENDS_FRIENDS_POTENTIAL);
		rootDescription:CreateRadio(FRIENDS_FRIENDS_CHOICE_MUTUAL, IsSelected, SetSelected, FRIENDS_FRIENDS_MUTUAL);
	end);
end

function FriendsFriendsFrameMixin:OnHide()
	PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE);
end

function FriendsFriendsFrameMixin:OnEvent(event, ...)
	if ( event == "BN_REQUEST_FOF_SUCCEEDED" ) then
		if ( self:IsShown() ) then
			FriendsFriendsFrame.view = FRIENDS_FRIENDS_ALL;
			FriendsFriendsFrameDropdown:Enable();
			FriendsFriendsFrameDropdown:GenerateMenu();

			local waitFrame = FriendsFriendsWaitFrame;
			-- need to stop the flashing because it's flashing with showWhenDone set to true
			if ( UIFrameIsFlashing(waitFrame) ) then
				UIFrameFlashStop(waitFrame);
			end
			waitFrame:Hide();
			FriendsFriendsList_Update();
		end
	elseif ( event == "BN_DISCONNECTED" ) then
		FriendsFriendsFrame_Close();
	end
end

function FriendsFriendsFrame_Reset()
	FriendsFriendsSendRequestButton:Disable();
	FriendsFriendsFrame.selection = nil;
end

function FriendsFriendsFrame_Show(bnetIDAccount)
	local accountName;
	bnetIDAccount, accountName = BNGetFriendInfoByID(bnetIDAccount);
	-- bail if that bnetIDAccount is not valid anymore
	if ( not bnetIDAccount ) then
		return;
	end
	FriendsFriendsFrameTitle:SetFormattedText(FRIENDS_FRIENDS_HEADER, FRIENDS_BNET_NAME_COLOR_CODE..accountName..FONT_COLOR_CODE_CLOSE);
	FriendsFriendsFrame.bnetIDAccount = bnetIDAccount;
	FriendsFriendsFrameDropdown:Disable();
	FriendsFriendsFrame_Reset();
	FriendsFriendsWaitFrame:Show();
	for i = 1, FRIENDS_FRIENDS_TO_DISPLAY, 1 do
		_G["FriendsFriendsButton"..i]:Hide();
	end
	FauxScrollFrame_Update(FriendsFriendsScrollFrame, 0, FRIENDS_FRIENDS_TO_DISPLAY, FRIENDS_FRAME_FRIENDS_FRIENDS_HEIGHT);
	StaticPopupSpecial_Show(FriendsFriendsFrame);
	BNRequestFOFInfo(bnetIDAccount);
end

function FriendsFrame_BattlenetInvite(button, bnetIDAccount)
	-- no button means click from UnitPopup dropdown, find the friend index by bnetIDAccount
	local index;
	if ( not button ) then
		index = BNGetFriendIndex(bnetIDAccount);
	else
		index = button.id;
	end
	if ( index ) then
		local numGameAccounts = BNGetNumFriendGameAccounts(index);
		if ( numGameAccounts > 1 ) then
			-- see if there is exactly one game account we could invite
			local numValidGameAccounts = 0;
			local lastGameAccountID;
			local lastGameAccountGUID;
			for i = 1, numGameAccounts do
				local _, _, client, _, realmID, faction, race, class, _, _, level, _, _, _, _, bnetIDGameAccount, _, _, _, guid = BNGetFriendGameAccountInfo(index, i);
				if ( client == BNET_CLIENT_WOW and faction == playerFactionGroup and realmID ~= 0 ) then
					numValidGameAccounts = numValidGameAccounts + 1;
					lastGameAccountID = bnetIDGameAccount;
					lastGameAccountGUID = guid;
				end
			end
			if ( numValidGameAccounts == 1 ) then
				FriendsFrame_InviteOrRequestToJoin(lastGameAccountGUID, lastGameAccountID);
				return;
			end

			-- if no button, now find the physical friend button to anchor the dropdown
			-- it might not exist if the list was scrolled
			if ( not button ) then
				local buttons = FriendsFrameFriendsScrollFrame.buttons;
				for i = 1, #buttons do
					if ( buttons[i].id == index and buttons[i].buttonType == FRIENDS_BUTTON_TYPE_BNET ) then
						button = buttons[i];
						break;
					end
				end
			end

			FriendsFrame_SetupTravelPassDropdown(index, button and button.travelPassButton or nil);
		else
			local bnetIDAccountFriend, accountName, battleTag, isBattleTag, characterName, bnetIDGameAccount = BNGetFriendInfo(index);
			if ( bnetIDGameAccount ) then
				local guid = select(20, BNGetGameAccountInfo(bnetIDGameAccount));
				FriendsFrame_InviteOrRequestToJoin(guid, bnetIDGameAccount);
			end
		end
	end
end

function FriendsFrame_SetupTravelPassDropdown(friendIndex, attachedTo)
	MenuUtil.CreateContextMenu(attachedTo, function(owner, rootDescription)
		rootDescription:SetTag("MENU_FRIENDS_TRAVEL_PASS");

		rootDescription:CreateTitle(TRAVEL_PASS_INVITE);

		local numGameAccounts = BNGetNumFriendGameAccounts(friendIndex);
		for i = 1, numGameAccounts do
			local text;
			local restriction = INVITE_RESTRICTION_NONE;
			local hasFocus, characterName, client, realmName, realmID, faction, race, class, _, _, level, _, _, _, _, bnetIDGameAccount, _, _, _, wowProjectID = BNGetFriendGameAccountInfo(friendIndex, i);
			if ( client == BNET_CLIENT_WOW ) then
				if ( faction ~= playerFactionGroup ) then
					restriction = INVITE_RESTRICTION_FACTION;
				elseif(wowProjectID ~= WOW_PROJECT_ID) then
					restriction = INVITE_RESTRICTION_WOW_PROJECT_ID;
				elseif ( realmID == 0 ) then
					restriction = INVITE_RESTRICTION_INFO;
				elseif ( realmID ~= playerNativeRealmID ) then
					-- The Classics don't allow grouping across realms
					restriction = INVITE_RESTRICTION_REALM;
				end
				if ( restriction == INVITE_RESTRICTION_NONE ) then
					text = string.format(FRIENDS_TOOLTIP_WOW_TOON_TEMPLATE, characterName, level, race, class);
				else
					text = string.format(FRIENDS_TOOLTIP_WOW_TOON_TEMPLATE, characterName..CANNOT_COOPERATE_LABEL, level, race, class);
				end
			else
				restriction = INVITE_RESTRICTION_CLIENT;
				text = BNet_GetClientEmbeddedAtlas(client, 18)..characterName;
			end

			if ( restriction == INVITE_RESTRICTION_NONE ) then
				rootDescription:CreateButton(text, function()
					local guid = select(20, BNGetGameAccountInfo(bnetIDGameAccount));
					FriendsFrame_InviteOrRequestToJoin(guid, bnetIDGameAccount);
				end);
			else
				local button = rootDescription:CreateButton(text);
				button:SetEnabled(false);
			end
		end
	end);
end

function CanCooperateWithGameAccount(bnetIDGameAccount)
	if (not bnetIDGameAccount) then
		return false;
	end
	local hasFocus, characterName, client, realmName, realmID, faction = BNGetGameAccountInfo(bnetIDGameAccount);
	return realmID and realmID > 0 and faction == playerFactionGroup;
end

--
-- travel pass
--

function CanGroupWithAccount(bnetIDAccount)
	if (not bnetIDAccount) then
		return false;
	end
	local index = BNGetFriendIndex(bnetIDAccount);
	if (not index) then
		return false;
	end
	local restriction = FriendsFrame_GetInviteRestriction(index);
	return (restriction == INVITE_RESTRICTION_NONE);
end

--Note that a single friend can have multiple GUIDs (if they're dual-boxing). This just gets one if there is one.
function FriendsFrame_GetPlayerGUIDFromIndex(index)
	local numGameAccounts = BNGetNumFriendGameAccounts(index);
	for i = 1, numGameAccounts do
		local guid = select(20, BNGetFriendGameAccountInfo(index, i));
		if ( guid ) then
			return guid;
		end
	end

	return nil;
end

function FriendsFrame_GetInviteRestriction(index)
	local restriction = INVITE_RESTRICTION_NO_GAME_ACCOUNTS;
	local numGameAccounts = BNGetNumFriendGameAccounts(index);
	for i = 1, numGameAccounts do
		local hasFocus, characterName, client, realmName, realmID, faction, _, _, _, _, _, _, _, _, _, _, _, _, _, _, wowProjectID = BNGetFriendGameAccountInfo(index, i);
		if ( client == BNET_CLIENT_WOW ) then
			if ( wowProjectID ~= WOW_PROJECT_ID ) then
				if (wowProjectID == WOW_PROJECT_CLASSIC) then
					restriction = max(INVITE_RESTRICTION_WOW_PROJECT_CLASSIC, restriction);
				elseif(wowProjectID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC) then
					restriction = max(INVITE_RESTRICTION_WOW_PROJECT_BCC, restriction);
				elseif(wowProjectID == WOW_PROJECT_WRATH_CLASSIC) then
					restriction = max(INVITE_RESTRICTION_WOW_PROJECT_WRATH, restriction);
				elseif(wowProjectID == WOW_PROJECT_CATACLYSM_CLASSIC) then
					restriction = max(INVITE_RESTRICTION_WOW_PROJECT_CATACLYSM, restriction);
				elseif(wowProjectID == WOW_PROJECT_MISTS_CLASSIC) then
					restriction = max(INVITE_RESTRICTION_WOW_PROJECT_MISTS, restriction);
				elseif(wowProjectID == WOW_PROJECT_MAINLINE) then
					restriction = max(INVITE_RESTRICTION_WOW_PROJECT_MAINLINE, restriction);
				else
					restriction = max(INVITE_RESTRICTION_WOW_PROJECT_ID, restriction);
				end
			elseif ( faction ~= playerFactionGroup ) then
				restriction = max(INVITE_RESTRICTION_FACTION, restriction);
			elseif ( realmID == 0 ) then
				restriction = max(INVITE_RESTRICTION_INFO, restriction);
			elseif ( realmID ~= playerNativeRealmID ) then
				-- The Classics don't allow grouping across realms
				restriction = max(INVITE_RESTRICTION_REALM, restriction);
			else
				-- there is at lease 1 game account that can be invited
				return INVITE_RESTRICTION_NONE;
			end
		else
			restriction = max(INVITE_RESTRICTION_CLIENT, restriction);
		end
	end
	return restriction;
end

function FriendsFrame_GetInviteRestrictionText(restriction)
	if ( restriction == INVITE_RESTRICTION_LEADER ) then
		return ERR_TRAVEL_PASS_NOT_LEADER;
	elseif ( restriction == INVITE_RESTRICTION_FACTION ) then
		return ERR_TRAVEL_PASS_NOT_ALLIED;
	elseif ( restriction == INVITE_RESTRICTION_REALM ) then
		return ERR_TRAVEL_PASS_DIFFERENT_REALM;
	elseif ( restriction == INVITE_RESTRICTION_INFO ) then
		return ERR_TRAVEL_PASS_NO_INFO;
	elseif ( restriction == INVITE_RESTRICTION_CLIENT ) then
		return ERR_TRAVEL_PASS_NOT_WOW;
	elseif ( restriction == INVITE_RESTRICTION_WOW_PROJECT_ID ) then
		return ERR_TRAVEL_PASS_WRONG_PROJECT;
	elseif ( restriction == INVITE_RESTRICTION_WOW_PROJECT_MAINLINE ) then
		return ERR_TRAVEL_PASS_WRONG_PROJECT_MAINLINE_OVERRIDE;
	elseif ( restriction == INVITE_RESTRICTION_WOW_PROJECT_CLASSIC ) then
		return ERR_TRAVEL_PASS_WRONG_PROJECT_CLASSIC_OVERRIDE;
	elseif ( restriction == INVITE_RESTRICTION_WOW_PROJECT_BCC ) then
		return ERR_TRAVEL_PASS_WRONG_PROJECT; -- ERR_TRAVEL_PASS_WRONG_PROJECT_BCC_OVERRIDE
	elseif ( restriction == INVITE_RESTRICTION_WOW_PROJECT_WRATH ) then
		return ERR_TRAVEL_PASS_WRONG_PROJECT; -- ERR_TRAVEL_PASS_WRONG_PROJECT_WRATH_OVERRIDE
	elseif ( restriction == INVITE_RESTRICTION_WOW_PROJECT_CATACLYSM ) then
		return ERR_TRAVEL_PASS_WRONG_PROJECT; -- ERR_TRAVEL_PASS_WRONG_PROJECT_CATACLYSM_OVERRIDE
	elseif ( restriction == INVITE_RESTRICTION_WOW_PROJECT_MISTS ) then
		return ERR_TRAVEL_PASS_WRONG_PROJECT; -- ERR_TRAVEL_PASS_WRONG_PROJECT_MISTS_OVERRIDE
	else
		return "";
	end
end

function TravelPassButton_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	local restriction = FriendsFrame_GetInviteRestriction(self:GetParent().id);
	if ( restriction == INVITE_RESTRICTION_NONE ) then
		local guid = FriendsFrame_GetPlayerGUIDFromIndex(self:GetParent().id);
		local inviteType = GetDisplayedInviteType(guid);
		if ( inviteType == "INVITE" ) then
			GameTooltip:SetText(TRAVEL_PASS_INVITE, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		elseif ( inviteType == "SUGGEST_INVITE" ) then
			GameTooltip:SetText(SUGGEST_INVITE, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		else --inviteType == "REQUEST_INVITE"
			GameTooltip:SetText(REQUEST_INVITE, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
			--For REQUEST_INVITE, we'll display other members in the group if there are any.
			local group = C_SocialQueue.GetGroupForPlayer(guid);
			local members = C_SocialQueue.GetGroupMembers(group);
			local numDisplayed = 0;
			for i=1, #members do
				if ( members[i].guid ~= guid ) then
					if ( numDisplayed == 0 ) then
						GameTooltip:AddLine(SOCIAL_QUEUE_ALSO_IN_GROUP);
					elseif ( numDisplayed >= 7 ) then
						GameTooltip:AddLine(SOCIAL_QUEUE_AND_MORE, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b, 1);
						break;
					end
					local name, color = SocialQueueUtil_GetRelationshipInfo(members[i].guid, nil, members[i].clubId);
					GameTooltip:AddLine(color..name..FONT_COLOR_CODE_CLOSE);

					numDisplayed = numDisplayed + 1;
				end
			end
		end
	else
		GameTooltip:SetText(TRAVEL_PASS_INVITE, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b, 1);
		GameTooltip:AddLine(FriendsFrame_GetInviteRestrictionText(restriction), RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true);
	end
	GameTooltip:Show();
end

function BattleTagInviteFrame_Show(name)
	BattleTagInviteFrame.BattleTag:SetText(name);
	if ( not BattleTagInviteFrame:IsShown() ) then
		StaticPopupSpecial_Show(BattleTagInviteFrame);
	end
end

function GroupsButton_Update(self)
	self.Icon:SetTexture("Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend");
	self:Show();
	self:Enable();
	self.Icon:SetDesaturated(false);
end



-- ============================================ GUILD ===============================================================================
GUILDFRAME_POPUPS = {
	"GuildEventLogFrame",
	"GuildInfoFrame",
	"GuildMemberDetailFrame",
	"GuildControlPopupFrame",
};

function GuildControlPopupFrame_OnLoad()
	local buttonText;
	for i=1, 17 do	
		buttonText = _G["GuildControlPopupFrameCheckbox"..i.."Text"];
		if ( buttonText ) then
			buttonText:SetText(_G["GUILDCONTROL_OPTION"..i]);
		end
	end
	GuildControlTabPermissionsViewTabText:SetText(GUILDCONTROL_VIEW_TAB);
	GuildControlTabPermissionsDepositItemsText:SetText(GUILDCONTROL_DEPOSIT_ITEMS);
	GuildControlTabPermissionsUpdateTextText:SetText(GUILDCONTROL_OPTION19); --option # is a lie, we're simply repurposing this globalstring from mainline
	ClearPendingGuildBankPermissions();

	if not C_GuildBank.IsGuildBankEnabled() then
		GuildControlPopupFrame_HideGuildBankOptions();
	end
end

--Need to call this function on an event since the guildroster is not available during OnLoad()
function GuildControlPopupFrame_Initialize()
	if ( GuildControlPopupFrame.initialized ) then
		return;
	end

	GuildControlSetRank(1);

	-- Select tab 1
	GuildBankTabPermissionsTab_OnClick(1);
	GuildControlPopupFrameDropdownButton_ClickedRank(1);

	GuildControlPopupFrame:SetScript("OnEvent", GuildControlPopupFrame_OnEvent);
	GuildControlPopupFrame.initialized = 1;
	GuildControlPopupFrame.rank = GuildControlGetRankName(1);
end

function GuildControlPopupFrame_OnShow()
	FriendsFrame:SetAttribute("UIPanelLayout-defined", nil);
	FriendsFrame.guildControlShow = 1;
	GuildControlPopupAcceptButton:Disable();
	-- Update popup
	GuildControlPopupFrame_Initialize();
	GuildControlPopupframe_Update();
	
	UIPanelWindows["FriendsFrame"].width = FriendsFrame:GetWidth() + GuildControlPopupFrame:GetWidth();
	UpdateUIPanelPositions(FriendsFrame);
	--GuildControlPopupFrame:RegisterEvent("GUILD_ROSTER_UPDATE"); --It was decided that having a risk of conflict when two people are editing the guild permissions at once is better than resetting whenever someone joins the guild or changes ranks.
	GuildControlPopupFrame:RegisterEvent("GUILD_RANKS_UPDATE");
end

function GuildControlPopupFrame_OnEvent (self, event, ...)
	if ( not IsGuildLeader(UnitName("player")) ) then
		GuildControlPopupFrame:Hide();
		return;
	end
	
	for i=1, GuildControlGetNumRanks() do
		if GuildControlGetRank() == i then
			GuildControlPopupFrameDropdown:GenerateMenu();
			break;
		end
	end
	
	local skipCheckboxUpdate = true;
	GuildControlPopupFrame.numSkipUpdates = GuildControlPopupFrame.numSkipUpdates - 1;
	if ( GuildControlPopupFrame.numSkipUpdates < 1 ) then
		GuildControlPopupFrame.numSkipUpdates = 0;
		skipCheckboxUpdate = false;
	end

	GuildControlPopupframe_Update(false, skipCheckboxUpdate);
end

function GuildControlPopupFrame_OnHide()
	FriendsFrame:SetAttribute("UIPanelLayout-defined", nil);
	FriendsFrame.guildControlShow = 0;

	UIPanelWindows["FriendsFrame"].width = FriendsFrame:GetWidth();
	UpdateUIPanelPositions();

	GuildControlPopupFrame.goldChanged = nil;
	GuildControlPopupFrame:UnregisterEvent("GUILD_ROSTER_UPDATE");
end

function GuildControlPopupframe_Update(loadPendingTabPermissions, skipCheckboxUpdate)
	local rankID = GuildControlGetRank();
	-- Skip non-tab specific updates to fix Bug  ID: 110210
	if ( not skipCheckboxUpdate ) then
		-- Update permission flags
		GuildControlCheckboxUpdate(C_GuildInfo.GuildControlGetRankFlags(rankID));
	end
	
	GuildControlPopupFrameEditBox:SetText(GuildControlGetRankName(rankID));
	if ( GuildControlPopupFrame.previousSelectedRank and GuildControlPopupFrame.previousSelectedRank ~= rankID ) then
		ClearPendingGuildBankPermissions();
	end
	GuildControlPopupFrame.previousSelectedRank = rankID;

	--If rank to modify is guild master then gray everything out
	if ( IsGuildLeader() and rankID == 1 ) then
		GuildBankTabLabel:SetVertexColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
		GuildControlTabPermissionsDepositItems:SetChecked(1);
		GuildControlTabPermissionsViewTab:SetChecked(1);
		GuildControlTabPermissionsUpdateText:SetChecked(1);
		GuildControlTabPermissionsDepositItems:Disable();
		GuildControlTabPermissionsViewTab:Disable();
		GuildControlTabPermissionsUpdateText:Disable();
		GuildControlTabPermissionsWithdrawItemsText:SetVertexColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
		GuildControlWithdrawItemsEditBox:SetNumeric(nil);
		GuildControlWithdrawItemsEditBox:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
		GuildControlWithdrawItemsEditBox:SetText(UNLIMITED);
		GuildControlWithdrawItemsEditBox:ClearFocus();
		GuildControlWithdrawItemsEditBoxMask:Show();
		GuildControlWithdrawGoldText:SetVertexColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
		GuildControlWithdrawGoldAmountText:SetVertexColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
		GuildControlWithdrawGoldEditBox:SetNumeric(nil);
		GuildControlWithdrawGoldEditBox:SetMaxLetters(0);
		GuildControlWithdrawGoldEditBox:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
		GuildControlWithdrawGoldEditBox:SetText(UNLIMITED);
		GuildControlWithdrawGoldEditBox:ClearFocus();
		GuildControlWithdrawGoldEditBoxMask:Show();
		GuildControlPopupFrameCheckbox15:Disable();
		GuildControlPopupFrameCheckbox16:Disable();
	else
		if ( GetNumGuildBankTabs() == 0 ) then
			-- No tabs, no permissions! Disable the tab related doohickies
			GuildBankTabLabel:SetVertexColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
			GuildControlTabPermissionsViewTab:Disable();
			GuildControlTabPermissionsDepositItems:Disable();
			GuildControlTabPermissionsUpdateText:Disable();
			GuildControlTabPermissionsWithdrawItemsText:SetVertexColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
			GuildControlWithdrawItemsEditBox:SetText(UNLIMITED);
			GuildControlWithdrawItemsEditBox:ClearFocus();
			GuildControlWithdrawItemsEditBoxMask:Show();
		else
			GuildBankTabLabel:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
			GuildControlTabPermissionsViewTab:Enable();
			GuildControlTabPermissionsWithdrawItemsText:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
			GuildControlWithdrawItemsEditBox:SetNumeric(1);
			GuildControlWithdrawItemsEditBox:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
			GuildControlWithdrawItemsEditBoxMask:Hide();
		end
		
		GuildControlWithdrawGoldText:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
		GuildControlWithdrawGoldAmountText:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
		GuildControlWithdrawGoldEditBox:SetNumeric(1);
		GuildControlWithdrawGoldEditBox:SetMaxLetters(MAX_GOLD_WITHDRAW_DIGITS);
		GuildControlWithdrawGoldEditBox:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		GuildControlWithdrawGoldEditBoxMask:Hide();
		GuildControlPopupFrameCheckbox15:Enable();
		GuildControlPopupFrameCheckbox16:Enable();

		-- Update tab specific info
		local viewTab, canDeposit, canUpdateText, numWithdrawals = GetGuildBankTabPermissions(GuildControlPopupFrameTabPermissions.selectedTab);
		if ( rankID == 1 ) then
			--If is guildmaster then force checkboxes to be selected
			viewTab = 1;
			canDeposit = 1;
			canUpdateText = 1;
		elseif ( loadPendingTabPermissions ) then
			local permissions = PENDING_GUILDBANK_PERMISSIONS[GuildControlPopupFrameTabPermissions.selectedTab];
			local value;
			value = permissions[GuildControlTabPermissionsViewTab:GetID()];
			if ( value ) then
				viewTab = value;
			end
			value = permissions[GuildControlTabPermissionsDepositItems:GetID()];
			if ( value ) then
				canDeposit = value;
			end
			value = permissions[GuildControlTabPermissionsUpdateText:GetID()];
			if ( value ) then
				canUpdateText = value;
			end
			value = permissions["withdraw"];
			if ( value ) then
				numWithdrawals = value;
			end
		end
		GuildControlTabPermissionsViewTab:SetChecked(viewTab);
		GuildControlTabPermissionsDepositItems:SetChecked(canDeposit);
		GuildControlTabPermissionsUpdateText:SetChecked(canUpdateText);
		GuildControlWithdrawItemsEditBox:SetText(numWithdrawals);
		local goldWithdrawLimit = GetGuildBankWithdrawGoldLimit();
		-- Only write to the editbox if the value hasn't been changed by the player
		if ( not GuildControlPopupFrame.goldChanged ) then
			if ( goldWithdrawLimit >= 0 ) then
				GuildControlWithdrawGoldEditBox:SetText(goldWithdrawLimit);
			else
				-- This is for the guild leader who defaults to -1
				GuildControlWithdrawGoldEditBox:SetText(MAX_GOLD_WITHDRAW);
			end
		end
		GuildControlPopup_UpdateDepositCheckbox();
	end
	
	--Only show available tabs
	local tab;
	local numTabs = GetNumGuildBankTabs();
	local name, permissionsTabBackground, permissionsText;
	for i=1, MAX_GUILDBANK_TABS do
		name = GetGuildBankTabInfo(i);
		tab = _G["GuildBankTabPermissionsTab"..i];
		
		if ( i <= numTabs ) then
			tab:Show();
			tab.tooltip = name;
			permissionsTabBackground = _G["GuildBankTabPermissionsTab"..i.."Background"];
			permissionsText = _G["GuildBankTabPermissionsTab"..i.."Text"];
			if (  GuildControlPopupFrameTabPermissions.selectedTab == i ) then
				tab:LockHighlight();
				permissionsTabBackground:SetTexCoord(0, 1.0, 0, 1.0);
				permissionsTabBackground:SetHeight(32);
				permissionsText:SetPoint("CENTER", permissionsTabBackground, "CENTER", 0, -3);
			else
				tab:UnlockHighlight();
				permissionsTabBackground:SetTexCoord(0, 1.0, 0, 0.875);
				permissionsTabBackground:SetHeight(28);
				permissionsText:SetPoint("CENTER", permissionsTabBackground, "CENTER", 0, -5);
			end
			if ( IsGuildLeader() and rankID == 1 ) then
				tab:Disable();
			else
				tab:Enable();
			end
		else
			tab:Hide();
		end
	end
end

function WithdrawGoldEditBox_Update()
	if ( not GuildControlPopupFrameCheckbox15:GetChecked() and not GuildControlPopupFrameCheckbox16:GetChecked() ) then
		GuildControlWithdrawGoldAmountText:SetVertexColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
		GuildControlWithdrawGoldEditBox:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
		GuildControlWithdrawGoldEditBox:ClearFocus();
		GuildControlWithdrawGoldEditBoxMask:Show();
	else
		GuildControlWithdrawGoldAmountText:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
		GuildControlWithdrawGoldEditBox:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		GuildControlWithdrawGoldEditBoxMask:Hide();
	end
end

function GuildControlPopupAcceptButton_OnClick()
	local amount = GuildControlWithdrawGoldEditBox:GetText();
	if(amount and amount ~= "" and amount ~= UNLIMITED and tonumber(amount) and tonumber(amount) > 0) then
		SetGuildBankWithdrawGoldLimit(amount);
	else
		SetGuildBankWithdrawGoldLimit(0);
	end
	SavePendingGuildBankTabPermissions()
	GuildControlSaveRank(GuildControlPopupFrameEditBox:GetText());
	GuildStatus_Update();
	GuildControlPopupAcceptButton:Disable();
	GuildControlPopupFrameDropdown:GenerateMenu();
	GuildControlPopupFrame:Hide();
	ClearPendingGuildBankPermissions();
end

function GuildControlPopupFrameDropdown_OnLoad(self)
	WowStyle1DropdownMixin.OnLoad(self);

	self:SetWidth(110);

	local function IsSelected(i)
		return GuildControlGetRank() == i;
	end

	local function SetSelected(i)
		GuildControlPopupFrame.numSkipUpdates = 0;
		GuildControlSetRank(i);
		GuildControlCheckboxUpdate(C_GuildInfo.GuildControlGetRankFlags(i));
		GuildControlPopupFrameEditBox:SetText(GuildControlGetRankName(i));
		GuildControlPopupFrameAddRankButton_OnUpdate();
		GuildControlPopupFrameRemoveRankButton_OnUpdate();
		GuildControlPopupAcceptButton:Disable();
	end

	self:SetupMenu(function(dropdown, rootDescription)
		rootDescription:SetTag("MENU_FRIENDS_GUILD_CONTROL");

		for i=1, GuildControlGetNumRanks() do
			local text = GuildControlGetRankName(i);
			rootDescription:CreateRadio(text, IsSelected, SetSelected, i);
		end
	end);
end

function GuildControlPopupFrameDropdownButton_ClickedRank(rank)
	GuildControlSetRank(rank);
	GuildControlPopupFrame.rank = GuildControlGetRankName(rank);
	GuildControlPopupFrame.goldChanged = nil;
	GuildControlPopupframe_Update();
	GuildControlPopupFrameAddRankButton_OnUpdate(GuildControlPopupFrameAddRankButton);
	GuildControlPopupFrameRemoveRankButton_OnUpdate();
	GuildControlPopupAcceptButton:Disable();
	GuildControlPopupFrameDropdown:GenerateMenu();
end

function GuildControlCheckboxUpdate(flags)
	for i=1, GUILD_NUM_RANK_FLAGS do
		local checkbox = _G["GuildControlPopupFrameCheckbox"..i];
		if ( checkbox ) then
			checkbox:SetChecked(flags[i]);
		else
			message("GuildControlPopupFrameCheckbox"..i.." does not exist!");
		end
	end
end

function GuildControlPopupFrameRemoveRankButton_OnClick()
	GuildControlDelRank(GuildControlGetRank());
	GuildControlPopupFrame.rank = GuildControlGetRankName(1);
	GuildControlSetRank(1);
	GuildStatus_Update();
	GuildControlPopupFrameEditBox:SetText(GuildControlGetRankName(1));
	GuildControlCheckboxUpdate(C_GuildInfo.GuildControlGetRankFlags(1));
	GuildControlPopupFrameDropdownButton_ClickedRank(1);

	-- Set this to call guildroster in the next frame
	--C_GuildInfo.GuildRoster();
	--GuildControlPopupFrame.update = 1;
end

function GuildControlPopupFrameRemoveRankButton_OnUpdate()
	local numRanks = GuildControlGetNumRanks()
	if ( (GuildControlGetRank() == numRanks) and (numRanks > 5) ) then
		GuildControlPopupFrameRemoveRankButton:Show();
		if ( FriendsFrame.playersInBotRank > 0 ) then
			GuildControlPopupFrameRemoveRankButton:Disable();
		else
			GuildControlPopupFrameRemoveRankButton:Enable();
		end
	else
		GuildControlPopupFrameRemoveRankButton:Hide();
	end
end

function GuildControlPopup_UpdateDepositCheckbox()
	if(GuildControlTabPermissionsViewTab:GetChecked()) then
		GuildControlTabPermissionsDepositItems:Enable();
		GuildControlTabPermissionsUpdateText:Enable();
	else
		GuildControlTabPermissionsDepositItems:Disable();
		GuildControlTabPermissionsUpdateText:Disable();
	end
end

function GuildBankTabPermissionsTab_OnClick(tab)
	GuildControlPopupFrameTabPermissions.selectedTab = tab;
	GuildControlPopupframe_Update(true, true);
end

-- Functions to allow canceling
function ClearPendingGuildBankPermissions()
	for i=1, MAX_GUILDBANK_TABS do
		PENDING_GUILDBANK_PERMISSIONS[i] = {};
	end
end

function SetPendingGuildBankTabPermissions(tab, id, checked)
	if ( not checked ) then
		checked = 0;
	end
	PENDING_GUILDBANK_PERMISSIONS[tab][id] = checked;
end

function SetPendingGuildBankTabWithdraw(tab, amount)
	PENDING_GUILDBANK_PERMISSIONS[tab]["withdraw"] = amount;
end

function SavePendingGuildBankTabPermissions()
	for index, value in pairs(PENDING_GUILDBANK_PERMISSIONS) do
		for i=1, 3 do
			if ( value[i] ) then
				-- treat 0 as false
				local boolValue = value[i];
				if ( type(boolValue) == "number" ) then
					boolValue = boolValue ~= 0;
				end
				SetGuildBankTabPermissions(index, i, boolValue);
			end
		end
		if ( value["withdraw"] ) then
			SetGuildBankTabItemWithdraw(index, value["withdraw"]);
		end
	end
end

function GuildControlPopupFrame_HideGuildBankOptions()
	GuildControlPopupFrameTabPermissions:Hide();
	GuildControlWithdrawGold:Hide();
	-- Guild Bank Repair
	GuildControlPopupFrameCheckbox15:Hide();
	-- Guild Bank Withdraw
	GuildControlPopupFrameCheckbox16:Hide();

	GuildControlPopupFrame:SetSize(320,321);
end

-- Guild event log functions
function ToggleGuildEventLog()
	if ( GuildEventLogFrame:IsShown() ) then
		GuildEventLogFrame:Hide();
	else
		GuildFramePopup_Show(GuildEventLogFrame);
	end
end

function GuildEventLog_Update()
	local numEvents = GetNumGuildEvents();
	local type, player1, player2, rank, year, month, day, hour;
	local msg;
	local buffer = "";
	local max = GuildEventMessage:GetFieldSize()
	local length = 0;
	for i=numEvents, 1, -1 do
		type, player1, player2, rank, year, month, day, hour = GetGuildEventInfo(i);
		if ( not player1 ) then
			player1 = UNKNOWN;
		end
		if ( not player2 ) then
			player2 = UNKNOWN;
		end
		if ( type == "invite" ) then
			msg = format(GUILDEVENT_TYPE_INVITE, player1, player2);
		elseif ( type == "join" ) then
			msg = format(GUILDEVENT_TYPE_JOIN, player1);
		elseif ( type == "promote" ) then
			msg = format(GUILDEVENT_TYPE_PROMOTE, player1, player2, rank);
		elseif ( type == "demote" ) then
			msg = format(GUILDEVENT_TYPE_DEMOTE, player1, player2, rank);
		elseif ( type == "remove" ) then
			msg = format(GUILDEVENT_TYPE_REMOVE, player1, player2);
		elseif ( type == "quit" ) then
			msg = format(GUILDEVENT_TYPE_QUIT, player1);
		end
		if ( msg ) then
			msg = msg.."|cff009999   "..format(GUILD_BANK_LOG_TIME, RecentTimeDate(year, month, day, hour)).."|r|n";
			length = length + msg:len();
			if(length>max) then
				i=0
			else
				buffer = buffer..msg
			end
		end
	end
	GuildEventMessage:SetText(buffer);
end

function FriendsFrameGuildStatusButton_OnClick(self, button)
	if ( button == "LeftButton" ) then
		GuildFrame.previousSelectedGuildMember = GuildFrame.selectedGuildMember;
		GuildFrame.selectedGuildMember = self.guildIndex;
		GuildFrame.selectedName = getglobal(self:GetName().."Name"):GetText();
		SetGuildRosterSelection(GuildFrame.selectedGuildMember);
		-- Toggle guild details frame
		if ( GuildMemberDetailFrame:IsVisible() and (GuildFrame.previousSelectedGuildMember and (GuildFrame.previousSelectedGuildMember == GuildFrame.selectedGuildMember)) ) then
			GuildMemberDetailFrame:Hide();
			GuildFrame.selectedGuildMember = 0;
			SetGuildRosterSelection(0);
		else
			GuildFramePopup_Show(GuildMemberDetailFrame);
		end
		GuildStatus_Update();
	else
		local guildIndex = self.guildIndex;
		local name, rank, rankIndex, level, class, zone, note, officernote, online = GetGuildRosterInfo(guildIndex);
		FriendsFrame_ShowDropdown(name, online);
	end
end

function GuildStatus_Update()
	-- Set the tab
	PanelTemplates_SetTab(FriendsFrame, FRIEND_TAB_GUILD);
	-- Show the frame
	ShowUIPanel(FriendsFrame);
	-- Number of players in the lowest rank
	FriendsFrame.playersInBotRank = 0

	local totalMembers, onlineMembers = GetNumGuildMembers();
	local numGuildMembers = 0;
	local showOffline = GetGuildRosterShowOffline();
	if (showOffline) then
		numGuildMembers = totalMembers;
	else
		numGuildMembers = onlineMembers;
	end
	local name, isAway;
	local fullName, rank, rankIndex, level, class, zone, note, officernote, online;
	local guildName, guildRankName, guildRankIndex = GetGuildInfo("player");
	local maxRankIndex = GuildControlGetNumRanks() - 1;
	local button;
	local onlinecount = 0;
	local guildIndex;

	-- Get selected guild member info
	fullName, rank, rankIndex, level, class, zone, note, officernote, online = GetGuildRosterInfo(GetGuildRosterSelection());
	GuildFrame.selectedName = fullName;
	-- If there's a selected guildmember
	if ( GetGuildRosterSelection() > 0 ) then
		local displayedName = Ambiguate(fullName, "guild");
		-- Update the guild member details frame
		GuildMemberDetailName:SetText(displayedName);
		GuildMemberDetailLevel:SetText(format(FRIENDS_LEVEL_TEMPLATE, level, class));
		GuildMemberDetailZoneText:SetText(zone);
		GuildMemberDetailRankText:SetText(rank);
		if ( online ) then
			GuildMemberDetailOnlineText:SetText(GUILD_ONLINE_LABEL);
		else
			GuildMemberDetailOnlineText:SetText(GuildFrame_GetLastOnline(GetGuildRosterSelection()));
		end
		-- Update public note
		if ( CanEditPublicNote() ) then
			PersonalNoteText:SetTextColor(1.0, 1.0, 1.0);
			if ( (not note) or (note == "") ) then
				note = GUILD_NOTE_EDITLABEL;
			end
		else
			PersonalNoteText:SetTextColor(0.65, 0.65, 0.65);
		end
		GuildMemberNoteBackground:EnableMouse(CanEditPublicNote());
		PersonalNoteText:SetText(note);
		-- Update officer note
		if ( C_GuildInfo.CanViewOfficerNote() ) then
			if ( C_GuildInfo.CanEditOfficerNote() ) then
				if ( (not officernote) or (officernote == "") ) then
					officernote = GUILD_OFFICERNOTE_EDITLABEL;
				end
				OfficerNoteText:SetTextColor(1.0, 1.0, 1.0);
			else
				OfficerNoteText:SetTextColor(0.65, 0.65, 0.65);
			end
			GuildMemberOfficerNoteBackground:EnableMouse(C_GuildInfo.CanEditOfficerNote());
			OfficerNoteText:SetText(officernote);

			-- Resize detail frame
			GuildMemberDetailOfficerNoteLabel:Show();
			GuildMemberOfficerNoteBackground:Show();
			GuildMemberDetailFrame:SetHeight(GUILD_DETAIL_OFFICER_HEIGHT);
		else
			GuildMemberDetailOfficerNoteLabel:Hide();
			GuildMemberOfficerNoteBackground:Hide();
			GuildMemberDetailFrame:SetHeight(GUILD_DETAIL_NORM_HEIGHT);
		end

		-- Manage guild member related buttons
		if ( CanGuildPromote() and ( rankIndex > 1 ) and ( rankIndex > (guildRankIndex + 1) ) ) then
			GuildFramePromoteButton:Enable();
		else 
			GuildFramePromoteButton:Disable();
		end
		if ( CanGuildDemote() and ( rankIndex >= 1 ) and ( rankIndex > guildRankIndex ) and ( rankIndex ~= maxRankIndex ) ) then
			GuildFrameDemoteButton:Enable();
		else
			GuildFrameDemoteButton:Disable();
		end
		-- Hide promote/demote buttons if both disabled
		if ( not GuildFrameDemoteButton:IsEnabled() and not GuildFramePromoteButton:IsEnabled() ) then
			GuildFramePromoteButton:Hide();
			GuildFrameDemoteButton:Hide();
			GuildMemberDetailRankText:SetPoint("RIGHT", "GuildMemberDetailFrame", "RIGHT", -10, 0);
		else
			GuildFramePromoteButton:Show();
			GuildFrameDemoteButton:Show();
			GuildMemberDetailRankText:SetPoint("RIGHT", "GuildFramePromoteButton", "LEFT", 3, 0);
		end
		if ( CanGuildRemove() and ( rankIndex >= 1 ) and ( rankIndex > guildRankIndex ) ) then
			GuildMemberRemoveButton:Enable();
		else
			GuildMemberRemoveButton:Disable();
		end
		if ( (UnitName("player") == displayedName) or (not online) ) then
			GuildMemberGroupInviteButton:Disable();
		else
			GuildMemberGroupInviteButton:Enable();
		end

		GuildFrame.selectedName = GetGuildRosterInfo(GetGuildRosterSelection()); 
	end
	
	-- Message of the day stuff
	local guildMOTD = GetGuildRosterMOTD();
	if ( CanEditMOTD() ) then
		if ( (not guildMOTD) or (guildMOTD == "") ) then
			--guildMOTD = GUILD_MOTD_EDITLABEL; -- A bug in the 1.12 lua code caused this to never actually appear.
		end
		GuildFrameNotesText:SetTextColor(1.0, 1.0, 1.0);
		GuildMOTDEditButton:Enable();
	else
		GuildFrameNotesText:SetTextColor(0.65, 0.65, 0.65);
		GuildMOTDEditButton:Disable();
	end
	GuildFrameNotesText:SetText(guildMOTD);

	-- Scrollbar stuff
	local showScrollBar = nil;
	if ( numGuildMembers > GUILDMEMBERS_TO_DISPLAY ) then
		showScrollBar = 1;
	end

	-- Get number of online members
	for i=1, numGuildMembers, 1 do
		name, rank, rankIndex, level, class, zone, note, officernote, online = GetGuildRosterInfo(i);
		if ( online ) then
			onlinecount = onlinecount + 1;
		end
		if ( rankIndex == maxRankIndex ) then
			FriendsFrame.playersInBotRank = FriendsFrame.playersInBotRank + 1;
		end
	end
	GuildFrameTotals:SetText(format(GetText("GUILD_TOTAL", nil, numGuildMembers), numGuildMembers));
	GuildFrameOnlineTotals:SetText(format(GUILD_TOTALONLINE, onlineMembers));

	-- Update global guild frame buttons
	if ( IsGuildLeader() ) then
		GuildFrameControlButton:Enable();
	else
		GuildFrameControlButton:Disable();
	end
	if ( CanGuildInvite() ) then
		GuildFrameAddMemberButton:Enable();
	else
		GuildFrameAddMemberButton:Disable();
	end


	if ( FriendsFrame.playerStatusFrame ) then
		-- Player specific info
		local guildOffset = FauxScrollFrame_GetOffset(GuildListScrollFrame);

		for i=1, GUILDMEMBERS_TO_DISPLAY, 1 do
			guildIndex = guildOffset + i;
			button = getglobal("GuildFrameButton"..i);
			button.guildIndex = guildIndex;

			fullName, rank, rankIndex, level, class, zone, note, officernote, online = GetGuildRosterInfo(guildIndex);
			if (fullName and (showOffline or online)) then
				local displayedName = Ambiguate(fullName, "guild");
				getglobal("GuildFrameButton"..i.."Name"):SetText(displayedName);
				getglobal("GuildFrameButton"..i.."Zone"):SetText(zone);
				getglobal("GuildFrameButton"..i.."Level"):SetText(level);
				getglobal("GuildFrameButton"..i.."Class"):SetText(class);
				if ( not online ) then
					getglobal("GuildFrameButton"..i.."Name"):SetTextColor(0.5, 0.5, 0.5);
					getglobal("GuildFrameButton"..i.."Zone"):SetTextColor(0.5, 0.5, 0.5);
					getglobal("GuildFrameButton"..i.."Level"):SetTextColor(0.5, 0.5, 0.5);
					getglobal("GuildFrameButton"..i.."Class"):SetTextColor(0.5, 0.5, 0.5);
				else
					getglobal("GuildFrameButton"..i.."Name"):SetTextColor(1.0, 0.82, 0.0);
					getglobal("GuildFrameButton"..i.."Zone"):SetTextColor(1.0, 1.0, 1.0);
					getglobal("GuildFrameButton"..i.."Level"):SetTextColor(1.0, 1.0, 1.0);
					getglobal("GuildFrameButton"..i.."Class"):SetTextColor(1.0, 1.0, 1.0);
				end
			else
				getglobal("GuildFrameButton"..i.."Name"):SetText(nil);
				getglobal("GuildFrameButton"..i.."Zone"):SetText(nil);
				getglobal("GuildFrameButton"..i.."Level"):SetText(nil);
				getglobal("GuildFrameButton"..i.."Class"):SetText(nil);
			end

			-- If need scrollbar resize columns
			if ( showScrollBar ) then
				getglobal("GuildFrameButton"..i.."Zone"):SetWidth(95);
				getglobal("GuildFrameButton"..i.."Class"):SetWidth(80);
			else
				getglobal("GuildFrameButton"..i.."Zone"):SetWidth(110);
			end

			-- Highlight the correct who
			if ( GetGuildRosterSelection() == guildIndex ) then
				button:LockHighlight();
			else
				button:UnlockHighlight();
			end
			
			if ( guildIndex > numGuildMembers ) then
				button:Hide();
			else
				button:Show();
			end
		end
		
		-- GuildFrameGuildListToggleButton:SetText(PLAYER_STATUS);
		-- If need scrollbar resize column headers
		if ( showScrollBar ) then
			WhoFrameColumn_SetWidth(GuildFrameColumnHeader2, 105);
			GuildFrameGuildListToggleButton:SetPoint("LEFT", "GuildFrame", "LEFT", 272, -98);
		else
			WhoFrameColumn_SetWidth(GuildFrameColumnHeader2, 120);
			GuildFrameGuildListToggleButton:SetPoint("LEFT", "GuildFrame", "LEFT", 295, -98);
		end
		-- ScrollFrame update
		FauxScrollFrame_Update(GuildListScrollFrame, numGuildMembers, GUILDMEMBERS_TO_DISPLAY, FRIENDS_FRAME_GUILD_HEIGHT );
		
		GuildPlayerStatusFrame:Show();
		GuildStatusFrame:Hide();
	else
		-- Guild specific info
		local year, month, day, hour;
		local yearlabel, monthlabel, daylabel, hourlabel;
		local guildOffset = FauxScrollFrame_GetOffset(GuildListScrollFrame);

		for i=1, GUILDMEMBERS_TO_DISPLAY, 1 do
			guildIndex = guildOffset + i;
			button = getglobal("GuildFrameGuildStatusButton"..i);
			button.guildIndex = guildIndex;

			fullName, rank, rankIndex, level, class, zone, note, officernote, online, isAway = GetGuildRosterInfo(guildIndex);
			if (fullName and (showOffline or online)) then
				local displayedName = Ambiguate(fullName, "guild");
				getglobal("GuildFrameGuildStatusButton"..i.."Name"):SetText(displayedName);
				getglobal("GuildFrameGuildStatusButton"..i.."Rank"):SetText(rank);
				getglobal("GuildFrameGuildStatusButton"..i.."Note"):SetText(note);

				if ( online ) then
					if ( isAway == 2 ) then
						getglobal("GuildFrameGuildStatusButton"..i.."Online"):SetText(CHAT_FLAG_DND);
					elseif ( isAway == 1 ) then
						getglobal("GuildFrameGuildStatusButton"..i.."Online"):SetText(CHAT_FLAG_AFK);
					else
						getglobal("GuildFrameGuildStatusButton"..i.."Online"):SetText(GUILD_ONLINE_LABEL);
					end

					getglobal("GuildFrameGuildStatusButton"..i.."Name"):SetTextColor(1.0, 0.82, 0.0);
					getglobal("GuildFrameGuildStatusButton"..i.."Rank"):SetTextColor(1.0, 1.0, 1.0);
					getglobal("GuildFrameGuildStatusButton"..i.."Note"):SetTextColor(1.0, 1.0, 1.0);
					getglobal("GuildFrameGuildStatusButton"..i.."Online"):SetTextColor(1.0, 1.0, 1.0);
				else
					getglobal("GuildFrameGuildStatusButton"..i.."Online"):SetText(GuildFrame_GetLastOnline(guildIndex));
					getglobal("GuildFrameGuildStatusButton"..i.."Name"):SetTextColor(0.5, 0.5, 0.5);
					getglobal("GuildFrameGuildStatusButton"..i.."Rank"):SetTextColor(0.5, 0.5, 0.5);
					getglobal("GuildFrameGuildStatusButton"..i.."Note"):SetTextColor(0.5, 0.5, 0.5);
					getglobal("GuildFrameGuildStatusButton"..i.."Online"):SetTextColor(0.5, 0.5, 0.5);
				end
			else
				getglobal("GuildFrameGuildStatusButton"..i.."Name"):SetText(nil);
				getglobal("GuildFrameGuildStatusButton"..i.."Rank"):SetText(nil);
				getglobal("GuildFrameGuildStatusButton"..i.."Note"):SetText(nil);
				getglobal("GuildFrameGuildStatusButton"..i.."Online"):SetText(nil);
			end

			-- If need scrollbar resize columns
			if ( showScrollBar ) then
				getglobal("GuildFrameGuildStatusButton"..i.."Note"):SetWidth(70);
			else
				getglobal("GuildFrameGuildStatusButton"..i.."Note"):SetWidth(85);
			end

			-- Highlight the correct who
			if ( GetGuildRosterSelection() == guildIndex ) then
				button:LockHighlight();
			else
				button:UnlockHighlight();
			end

			if ( guildIndex > numGuildMembers ) then
				button:Hide();
			else
				button:Show();
			end
		end
		
		-- GuildFrameGuildListToggleButton:SetText(GUILD_STATUS);
		-- If need scrollbar resize columns
		if ( showScrollBar ) then
			WhoFrameColumn_SetWidth(GuildFrameGuildStatusColumnHeader3, 75);
			GuildFrameGuildListToggleButton:SetPoint("LEFT", "GuildFrame", "LEFT", 272, -98);
		else
			WhoFrameColumn_SetWidth(GuildFrameGuildStatusColumnHeader3, 90);
			GuildFrameGuildListToggleButton:SetPoint("LEFT", "GuildFrame", "LEFT", 295, -98);
		end
		
		-- ScrollFrame update
		FauxScrollFrame_Update(GuildListScrollFrame, numGuildMembers, GUILDMEMBERS_TO_DISPLAY, FRIENDS_FRAME_GUILD_HEIGHT );

		GuildPlayerStatusFrame:Hide();
		GuildStatusFrame:Show();
	end
end

function GuildFramePopup_Show(frame)
	local name = frame:GetName();
	for index, value in ipairs(GUILDFRAME_POPUPS) do
		if ( name ~= value ) then
			_G[value]:Hide();
		end
	end
	frame:Show();
end

function GuildFramePopup_HideAll()
	for index, value in ipairs(GUILDFRAME_POPUPS) do
		_G[value]:Hide();
	end
end

function InGuildCheck(frame)
	if (not frame) then
		frame = FriendsFrame;
	end
	if ( not IsInGuild() ) then
		PanelTemplates_DisableTab( frame, FRIEND_TAB_GUILD );
		if ( frame.selectedTab == FRIEND_TAB_GUILD ) then
			frame.selectedTab = 1;
		end
	else
		PanelTemplates_EnableTab( frame, FRIEND_TAB_GUILD );
	end
end

function GuildFrameControlButton_OnUpdate()
	if ( FriendsFrame.guildControlShow == 1 ) then
		GuildFrameControlButton:LockHighlight();
	else
		GuildFrameControlButton:UnlockHighlight();
	end
	-- Janky way to make sure a change made to the guildroster will reflect in the guildroster call
	if ( GuildControlPopupFrame.update == 1 ) then
		GuildControlPopupFrame.update = 2;
	elseif ( GuildControlPopupFrame.update == 2 ) then
		C_GuildInfo.GuildRoster();
		GuildControlPopupFrame.update = nil;
	end
end

function GuildControlPopupFrameAddRankButton_OnUpdate()
	if ( GuildControlGetNumRanks() >= 10 ) then
		GuildControlPopupFrameAddRankButton:Disable();
	else
		GuildControlPopupFrameAddRankButton:Enable();
	end
end

function GuildFrameGuildListToggleButton_OnClick()
	if ( FriendsFrame.playerStatusFrame ) then
		FriendsFrame.playerStatusFrame = nil;
	else
		FriendsFrame.playerStatusFrame = 1;		
	end
	GuildStatus_Update();
end

function GuildFrame_GetLastOnline(guildIndex)
	local year, month, day, hour = GetGuildRosterLastOnline(guildIndex);
	local lastOnline;
	if ( (year == 0) or (year == nil) ) then
		if ( (month == 0) or (month == nil) ) then
			if ( (day == 0) or (day == nil) ) then
				if ( (hour == 0) or (hour == nil) ) then
					lastOnline = LASTONLINE_MINS;
				else
					lastOnline = format(GetText("LASTONLINE_HOURS", nil, hour), hour);
				end
			else
				lastOnline = format(GetText("LASTONLINE_DAYS", nil, day), day);
			end
		else
			lastOnline = format(GetText("LASTONLINE_MONTHS", nil, month), month);
		end
	else
		lastOnline = format(GetText("LASTONLINE_YEARS", nil, year), year);
	end
	return lastOnline;
end

function ToggleGuildInfoFrame()
	if ( GuildInfoFrame:IsShown() ) then
		GuildInfoFrame:Hide();
	else
		GuildFramePopup_Show(GuildInfoFrame);
	end
end

function FriendsFrame_UpdateVisibleTabs()
	local numTabs = FRIEND_TAB_BASE_COUNT;
	if (FriendsFrame_UpdateGuildTabVisibility()) then
		numTabs = numTabs + 1;
	end
end

function FriendsFrame_UpdateGuildTabVisibility()
	local guildsTab = _G["FriendsFrameTab"..FRIEND_TAB_GUILD];
	local whoTab = _G["FriendsFrameTab"..FRIEND_TAB_WHO]; -- Next tab to the left.
	local raidTab = _G["FriendsFrameTab"..FRIEND_TAB_RAID]; -- Next tab to the right.
	if (FriendsFrame_ShouldShowGuildTab()) then
		guildsTab:Show();
		raidTab:SetPoint("LEFT", guildsTab, "RIGHT", -14, 0);
	else
		guildsTab:Hide();
		raidTab:SetPoint("LEFT", whoTab, "RIGHT", -14, 0);
		if (PanelTemplates_GetSelectedTab(FriendsFrame) == FRIEND_TAB_GUILD) then
			PanelTemplates_SetTab(FriendsFrame, FRIEND_TAB_FRIENDS);
		end
	end
	return guildsTab:IsShown();
end

function FriendsFrame_ShouldShowGuildTab()
	return C_CVar.GetCVarBool("useClassicGuildUI");
end

function GuildFrame_CheckName()
	if ( GuildFrame.hasForcedNameChange ) then
		local clickableHelp = false
		GuildNameChangeAlertFrame:Show();

		if ( IsGuildLeader() ) then
			GuildNameChangeFrame.gmText:Show();
			GuildNameChangeFrame.memberText:Hide();
			GuildNameChangeFrame.button:SetText(ACCEPT);
			GuildNameChangeFrame.button:SetPoint("TOP", GuildNameChangeFrame.editBox, "BOTTOM", 0, -10);
			GuildNameChangeFrame.renameText:Show();
			GuildNameChangeFrame.editBox:Show();
		else
			clickableHelp = GuildNameChangeAlertFrame.topAnchored;
			GuildNameChangeFrame.gmText:Hide();
			GuildNameChangeFrame.memberText:Show();
			GuildNameChangeFrame.button:SetText(OKAY);
			GuildNameChangeFrame.button:SetPoint("TOP", GuildNameChangeFrame.memberText, "BOTTOM", 0, -30);
			GuildNameChangeFrame.renameText:Hide();
			GuildNameChangeFrame.editBox:Hide();
		end


		if ( clickableHelp ) then
			GuildNameChangeAlertFrame.alert:SetFontObject(GameFontHighlight);
			GuildNameChangeAlertFrame.alert:ClearAllPoints();
			GuildNameChangeAlertFrame.alert:SetPoint("BOTTOM", GuildNameChangeAlertFrame, "CENTER", 0, 0);
			GuildNameChangeAlertFrame.alert:SetWidth(190);
			GuildNameChangeAlertFrame:ClearAllPoints();
			GuildNameChangeAlertFrame:SetPoint("CENTER", 0, 30);
			GuildNameChangeAlertFrame:SetSize(256, 60);
			GuildNameChangeAlertFrame:Enable();
			GuildNameChangeAlertFrame.clickText:Show();
			GuildNameChangeFrame:Hide();
		else
			GuildNameChangeAlertFrame.alert:SetFontObject(GameFontHighlightMedium);
			GuildNameChangeAlertFrame.alert:ClearAllPoints();
			GuildNameChangeAlertFrame.alert:SetPoint("CENTER", GuildNameChangeAlertFrame, "CENTER", 0, 0);
			GuildNameChangeAlertFrame.alert:SetWidth(220);
			GuildNameChangeAlertFrame:SetPoint("TOP", 0, -82);
			GuildNameChangeAlertFrame:SetSize(300, 40);
			GuildNameChangeAlertFrame:Disable();
			GuildNameChangeAlertFrame.clickText:Hide();
			GuildNameChangeFrame:Show();
		end
	else
		GuildNameChangeAlertFrame:Hide();
		GuildNameChangeFrame:Hide();
	end
end
