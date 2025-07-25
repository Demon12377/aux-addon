---------------------------------------------------------------
-- PVE FRAME
---------------------------------------------------------------

PVE_FRAME_BASE_WIDTH = 563;

-- TODO: SHARING PASS (PVEFrame is currently forked)
-- Note: These need to be uncommented out from PVEFrame.xml as well.
local panels = {
	{ name = "GroupFinderFrame", addon = nil },
	{ name = "PVPQueueFrame", addon = "Blizzard_PVPUI" },
	{ name = "ChallengesFrame", addon = "Blizzard_ChallengesUI", check = function() return UnitLevel("player") >= GetMaxLevelForExpansionLevel(GetExpansionLevel()) and C_ChallengeMode.IsChallengeModeEnabled(); end, },
}

function PVEFrame_OnLoad(self)
	-- If there is only 1 tab, then we don't need to show tabs
	self.showTabs = (#panels > 1);

	RaiseFrameLevel(self.shadows);
	PanelTemplates_SetNumTabs(self, #panels);

	self:RegisterEvent("AJ_PVP_ACTION");
	self:RegisterEvent("AJ_PVP_SKIRMISH_ACTION");
	self:RegisterEvent("AJ_PVP_LFG_ACTION");
	self:RegisterEvent("AJ_PVP_RBG_ACTION");
	self:RegisterEvent("AJ_PVE_LFG_ACTION");

	self.maxTabWidth = (self:GetWidth() - 19) / #panels;
end

function PVEFrame_OnShow(self)
	if(self.showTabs) then
		for index, panel in pairs(panels) do
			if (panel.check and not panel.check()) then
				PanelTemplates_HideTab(self, index);
			else
				PanelTemplates_ShowTab(self, index);
			end
		end
	end
end

function PVEFrame_OnEvent(self, event, ...)
	if ( event == "AJ_PVP_ACTION" ) then
		local id = ...;
		ShowPVPQueueUI();
		HonorFrameSpecificList_FindAndSelectBattleground(id);
		HonorFrame_SetType("specific");
	elseif ( event == "AJ_PVP_SKIRMISH_ACTION" ) then
		ShowPVPQueueUI();
		HonorFrame_SetType("bonus");

		HonorFrameBonusFrame_SelectButton(HonorFrame.BonusFrame.Arena1Button);
	elseif ( event == "AJ_PVE_LFG_ACTION" ) then
		PVEFrame_ShowFrame("GroupFinderFrame", "LFGListPVEStub");
	elseif ( event == "AJ_PVP_LFG_ACTION" ) then
		PVEFrame_ShowFrame("PVPUIFrame", "LFGListPVPStub");
	elseif ( event == "AJ_PVP_RBG_ACTION" ) then
		ShowPVPQueueUI();
		HonorFrame_SetType("bonus");

		HonorFrameBonusFrame_SelectButton(HonorFrame.BonusFrame.RandomBGButton);
	end
end

function PVEFrame_ToggleFrame(sidePanelName, selection)
	local canUse = C_LFGInfo.CanPlayerUseGroupFinder() and UnitLevel("player") >= SHOW_LFD_LEVEL;
	if ( not canUse or Kiosk.IsEnabled() ) then
		return;
	end
	local self = PVEFrame;
	if ( self:IsShown() ) then
		if ( sidePanelName ) then
			local sidePanel = _G[sidePanelName];
			if ( sidePanel ) then
				--We know the panel is loaded, so try to dereference the selection
				if ( type(selection) == "string" ) then
					selection = _G[selection];
				end
				if ( sidePanel:IsShown() and (not selection or not sidePanel.getSelection or sidePanel:getSelection() == selection) ) then
					HideUIPanel(self);
					return;
				end
			end
		else
			HideUIPanel(self);
			return;
		end
	end
	PVEFrame_ShowFrame(sidePanelName, selection);
end
function PVEFrame_ShowFrame(sidePanelName, selection)
	local self = PVEFrame;
	-- find side panel
	local tabIndex;
	if ( sidePanelName ) then
		for index, data in pairs(panels) do
			if ( data.name == sidePanelName ) then
				tabIndex = index;
				break;
			end
		end
	else
		-- no side panel specified, check current panel
		if ( self.activeTabIndex ) then
			tabIndex = self.activeTabIndex;
		else
			-- no current panel, go to the first panel
			tabIndex = 1;
		end
	end
	if ( not tabIndex ) then
		return;
	end
	if ( panels[tabIndex].check and not panels[tabIndex].check() ) then
		tabIndex = self.activeTabIndex or 1;
	end

	-- load addon if needed
	if ( panels[tabIndex].addon ) then
		UIParentLoadAddOn(panels[tabIndex].addon);
		panels[tabIndex].addon = nil;
	end

	-- we've loaded the AddOn, so try to dereference the selection if needed
	if ( type(selection) == "string" ) then
		selection = _G[selection];
	end

	-- show it
	ShowUIPanel(self);
	self.activeTabIndex = tabIndex;
	if(self.showTabs) then
		PanelTemplates_SetTab(self, tabIndex);
	end
	self:SetWidth(PVE_FRAME_BASE_WIDTH);
	UpdateUIPanelPositions(PVEFrame);
	for index, data in pairs(panels) do
		local panel = _G[data.name];
		if ( index == tabIndex ) then
			panel:Show();
			if( panel.update ) then
				panel:update(selection);
			end
		elseif ( panel ) then
			panel:Hide();
		end
	end
end

function PVEFrame_TabOnClick(self)
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
	PVEFrame_ShowFrame(panels[self:GetID()].name);
end

function PVEFrame_HideLeftInset()
    PVEFrameLeftInset:Hide();
    PVEFrameBlueBg:Hide();
    PVEFrameTLCorner:Hide();
    PVEFrameTRCorner:Hide();
    PVEFrameBRCorner:Hide();
    PVEFrameBLCorner:Hide();
    PVEFrameLLVert:Hide();
    PVEFrameRLVert:Hide();
    PVEFrameBottomLine:Hide();
    PVEFrameTopLine:Hide();
    PVEFrameTopFiligree:Hide();
    PVEFrameBottomFiligree:Hide();
    PVEFrame.shadows:Hide();
end

function PVEFrame_ShowLeftInset()
    PVEFrameLeftInset:Show();
    PVEFrameBlueBg:Show();
    PVEFrameTLCorner:Show();
    PVEFrameTRCorner:Show();
    PVEFrameBRCorner:Show();
    PVEFrameBLCorner:Show();
    PVEFrameLLVert:Show();
    PVEFrameRLVert:Show();
    PVEFrameBottomLine:Show();
    PVEFrameTopLine:Show();
    PVEFrameTopFiligree:Show();
    PVEFrameBottomFiligree:Show();
    PVEFrame.shadows:Show();
end

---------------------------------------------------------------
-- GROUP FINDER
---------------------------------------------------------------

local groupFrames = { "LFDParentFrame", "RaidFinderFrame", "LFGListPVEStub", "ScenarioFinderFrame" }

function GroupFinderFrame_OnLoad(self)
	SetPortraitToTexture(self.groupButton1.icon, "Interface\\Icons\\INV_Helmet_08");
	self.groupButton1.name:SetText(LOOKING_FOR_DUNGEON_PVEFRAME);
	SetPortraitToTexture(self.groupButton2.icon, "Interface\\LFGFrame\\UI-LFR-PORTRAIT");
	self.groupButton2.name:SetText(RAID_FINDER_PVEFRAME);
	SetPortraitToTexture(self.groupButton3.icon, "Interface\\Icons\\Achievement_General_StayClassy");
	self.groupButton3.name:SetText(LFGLIST_NAME);
	SetPortraitToTexture(self.groupButton4.icon, "Interface\\Icons\\Icon_Scenarios");
	self.groupButton4.name:SetText(SCENARIOS_PVEFRAME);

	GroupFinderFrame_EvaluateButtonVisibility(self);

	self:RegisterEvent("LFG_UPDATE_RANDOM_INFO");
	self:RegisterEvent("PLAYER_LEVEL_CHANGED");

	-- set up accessors
	self.getSelection = GroupFinderFrame_GetSelection;
	self.update = GroupFinderFrame_Update;
end

function GroupFinderFrame_EvaluateButtonVisibility(self)
	local visible = C_LFGInfo.IsLFDEnabled();
	local canUse, failureReason = C_LFGInfo.CanPlayerUseLFD();
	if not visible then
		self.groupButton1:Hide();
	elseif not canUse then
		self.groupButton1:Show();
		GroupFinderFrameButton_SetEnabled(self.groupButton1, false);
		self.groupButton1.tooltip = failureReason;
	else
		self.groupButton1:Show();
		self.groupButton1.tooltip = nil;
		GroupFinderFrameButton_SetEnabled(self.groupButton1, true);
	end

	visible = C_LFGInfo.IsLFREnabled();
	canUse, failureReason = C_LFGInfo.CanPlayerUseLFR();
	if not visible then
		self.groupButton2:Hide();

		-- To avoid a weird gap, move the other buttons around if LFR is off
		local altAnchorPoint = self.groupButton1.altAnchorPoint;
		local altAnchorRelativePoint = nil;
		local altXOffset = tonumber(self.groupButton1.altXOffset);
		local altYOffset = tonumber(self.groupButton1.altYOffset);
		self.groupButton1:SetPoint(altAnchorPoint, altXOffset, altYOffset);
		altAnchorPoint = self.groupButton3.altAnchorPoint;
		altAnchorRelativePoint = self.groupButton3.altAnchorRelativePoint;
		altXOffset = tonumber(self.groupButton3.altXOffset);
		altYOffset = tonumber(self.groupButton3.altYOffset);
		self.groupButton3:SetPoint(altAnchorPoint, self.groupButton1, altAnchorRelativePoint, altXOffset, altYOffset);
	elseif not canUse then
		self.groupButton2:Show();
		GroupFinderFrameButton_SetEnabled(self.groupButton2, false);
		self.groupButton2.tooltip = failureReason;
	else
		self.groupButton2:Show();
		self.groupButton2.tooltip = nil;
		GroupFinderFrameButton_SetEnabled(self.groupButton2, true);
	end

	visible = C_LFGList.IsPremadeGroupFinderEnabled();
	canUse, failureReason = C_LFGInfo.CanPlayerUsePremadeGroup();
	if not visible then
		self.groupButton3:Hide();
	elseif not canUse then
		self.groupButton3:Show();
		GroupFinderFrameButton_SetEnabled(self.groupButton3, false);
		self.groupButton3.tooltip = failureReason;
	else
		self.groupButton3:Show();
		self.groupButton3.tooltip = nil;
		GroupFinderFrameButton_SetEnabled(self.groupButton3, true);
	end

	visible = (ScenariosList and #ScenariosList > 0) or false
	canUse, failureReason = C_LFGInfo.CanPlayerUseScenarioFinder();
	if not visible then
		self.groupButton4:Hide();
	elseif not canUse then
		self.groupButton4:Show();
		GroupFinderFrameButton_SetEnabled(self.groupButton4, false);
		self.groupButton4.tooltip = failureReason;
	else
		self.groupButton4:Show();
		self.groupButton4.tooltip = nil;
		GroupFinderFrameButton_SetEnabled(self.groupButton4, true);
	end
end

function GroupFinderFrameButton_SetEnabled(button, enabled)
	if ( button:IsEnabled() == enabled ) then
		return
	end

	if ( enabled ) then
		button.bg:SetTexCoord(0.00390625, 0.87890625, 0.75195313, 0.83007813);
		button.name:SetFontObject("GameFontNormalLarge");
	else
		button.bg:SetTexCoord(0.00390625, 0.87890625, 0.67187500, 0.75000000);
		button.name:SetFontObject("GameFontDisableLarge");
	end
	SetDesaturation(button.icon, not enabled);
	SetDesaturation(button.ring, not enabled);
	button:SetEnabled(enabled);
end

function GroupFinderFrame_OnEvent(self, event, ...)
	GroupFinderFrame_EvaluateButtonVisibility(self);
end

function GroupFinderFrame_GetSelection(self)
	return self.selection;
end

function GroupFinderFrame_GetSelectedIndex(self)
	return self.selectionIndex;
end

function GroupFinderFrame_Update(self, frame)
	GroupFinderFrame_ShowGroupFrame(frame);
end

function GroupFinderFrame_EvaluateHelpTips(self)
	if not GetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_LFG_LIST) and C_LFGInfo.CanPlayerUsePremadeGroup() then
		local helpTipInfo = {
			text = LFG_LIST_TUTORIAL_ALERT,
			buttonStyle = HelpTip.ButtonStyle.Close,
			cvarBitfield = "closedInfoFrames",
			bitfieldFlag = LE_FRAME_TUTORIAL_LFG_LIST,
			targetPoint = HelpTip.Point.TopEdgeCenter,
		};
		HelpTip:Show(self, helpTipInfo, GroupFinderFrameGroupButton3);
	end
end

function GroupFinderFrame_OnShow(self)
	if(SetPortraitAtlasRaw) then
		PVEFrame:SetPortraitAtlasRaw("groupfinder-eye-frame");
	else
		PVEFramePortrait:SetAtlas("groupfinder-eye-frame");
	end
	PVEFrame:SetTitle(GROUP_FINDER);
	GroupFinderFrame_EvaluateButtonVisibility(self);
	GroupFinderFrame_EvaluateHelpTips(self);
	ScenarioQueueFrame_Update();
end

function GroupFinderFrame_ShowGroupFrame(frame)
	frame = frame or GroupFinderFrame.selection or (C_LFGInfo.CanPlayerUseLFD() and LFDParentFrame or LFGListPVEStub);
	-- hide the other frames and select the right button
	for index, frameName in pairs(groupFrames) do
		local groupFrame = _G[frameName];
		if ( groupFrame == frame ) then
			GroupFinderFrame_SelectGroupButton(index);
		else
			groupFrame:Hide();
		end
	end
	frame:Show();
	GroupFinderFrame.selection = frame;
end

function GroupFinderFrame_SelectGroupButton(index)
	local self = GroupFinderFrame;
	for i = 1, #groupFrames do
		local button = self["groupButton"..i];
		if ( i == index ) then
			button.bg:SetTexCoord(0.00390625, 0.87890625, 0.59179688, 0.66992188);
		else
			button.bg:SetTexCoord(0.00390625, 0.87890625, 0.75195313, 0.83007813);
		end
	end

	GroupFinderFrame.selectionIndex = index
end

function GroupFinderFrameGroupButton_OnClick(self)
	local frameName = groupFrames[self:GetID()];
	GroupFinderFrame_ShowGroupFrame(_G[frameName]);
end

function GroupFinderFrameGroupButton_OnEnter(self)
	if self.tooltip then
		GameTooltip:SetOwner(self, "ANCHOR_TOP");
		GameTooltip_AddNormalLine(GameTooltip, self.tooltip);
		GameTooltip:Show();
	end
end
