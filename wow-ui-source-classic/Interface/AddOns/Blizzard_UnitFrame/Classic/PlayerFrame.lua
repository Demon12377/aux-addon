REQUIRED_REST_HOURS = 5;

PLAYER_FRAME_UNLOCKED = PLAYER_FRAME_UNLOCKED or nil;
PLAYER_FRAME_CASTBARS_SHOWN = PLAYER_FRAME_CASTBARS_SHOWN or nil;

function PlayerFrame_OnLoad(self)
	PlayerFrameHealthBar.LeftText = PlayerFrameHealthBarTextLeft;
	PlayerFrameHealthBar.RightText = PlayerFrameHealthBarTextRight;
	PlayerFrameManaBar.LeftText = PlayerFrameManaBarTextLeft;
	PlayerFrameManaBar.RightText = PlayerFrameManaBarTextRight;

	local healthBar = PlayerFrame_GetHealthBar();
	local manaBar = PlayerFrame_GetManaBar();
	UnitFrame_Initialize(self, "player", PlayerName, PlayerPortrait,
						 healthBar,
						 PlayerFrameHealthBarText,
						 manaBar,
						 PlayerFrameManaBarText,
						 nil, nil, nil,
						 healthBar.MyHealPredictionBar,
						 healthBar.OtherHealPredictionBar,
						 healthBar.TotalAbsorbBar,
						 healthBar.TotalAbsorbBarOverlay,
						 self.rightFrame.textFrame.overAbsorbGlow,
						 self.rightFrame.textFrame.overHealAbsorbGlow,
						 healthBar.HealAbsorbBar,
						 healthBar.HealAbsorbBarLeftShadow,
						 healthBar.HealAbsorbBarRightShadow,
						 manaBar.ManaCostPredictionBar);

	self.statusCounter = 0;
	self.statusSign = -1;

	CombatFeedback_Initialize(self, PlayerHitIndicator, 30);

	PlayerFrame_Update();
	self:RegisterEvent("UNIT_LEVEL");
	self:RegisterEvent("UNIT_FACTION");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("PLAYER_ENTER_COMBAT");
	self:RegisterEvent("PLAYER_LEAVE_COMBAT");
	self:RegisterEvent("PLAYER_REGEN_DISABLED");
	self:RegisterEvent("PLAYER_REGEN_ENABLED");
	self:RegisterEvent("PLAYER_UPDATE_RESTING");
	self:RegisterEvent("PARTY_LEADER_CHANGED");
	self:RegisterEvent("GROUP_ROSTER_UPDATE");
	self:RegisterEvent("READY_CHECK");
	self:RegisterEvent("READY_CHECK_CONFIRM");
	self:RegisterEvent("READY_CHECK_FINISHED");
	self:RegisterEvent("UNIT_ENTERED_VEHICLE");
	self:RegisterEvent("UNIT_ENTERING_VEHICLE");
	self:RegisterEvent("UNIT_EXITING_VEHICLE");
	self:RegisterEvent("UNIT_EXITED_VEHICLE");
	self:RegisterEvent("PLAYER_FLAGS_CHANGED");
	self:RegisterEvent("VARIABLES_LOADED");
	self:RegisterUnitEvent("UNIT_COMBAT", "player", "vehicle");
	self:RegisterUnitEvent("UNIT_MAXPOWER", "player", "vehicle");

	-- Chinese playtime stuff
	self:RegisterEvent("PLAYTIME_CHANGED");

	PlayerAttackBackground:SetVertexColor(0.8, 0.1, 0.1);
	PlayerAttackBackground:SetAlpha(0.4);

	self:SetClampRectInsets(20, 0, 0, 0);

	UIParent_UpdateTopFramePositions();

	local function OpenContextMenu(frame, unit, button, isKeyPress)
		local which = nil;
		local contextData = {
			fromPlayerFrame = true;
		};

		if self.unit == "vehicle" then
			which = "VEHICLE";
			contextData.unit = "vehicle";
		else
			which = "SELF";
			contextData.unit = "player";
		end
		UnitPopup_OpenMenu(which, contextData);
	end

	SecureUnitButton_OnLoad(self, "player", OpenContextMenu);
end

--
-- Helper functions to access frequently needed UI.
--

function PlayerFrame_GetHealthBar()
	return PlayerFrame.HealthBar;
end

function PlayerFrame_GetManaBar()
	return PlayerFrame.ManaBar;
end


--This is overwritten in LocalizationPost for different languages.
function PlayerFrame_UpdateLevelTextAnchor(level)
	if ( level >= 100 ) then
		PlayerLevelText:SetPoint("CENTER", PlayerFrameTexture, "CENTER", -64, -16);
	else
		PlayerLevelText:SetPoint("CENTER", PlayerFrameTexture, "CENTER", -63, -16);
	end
end

function PlayerFrame_Update ()
	if ( UnitExists("player") ) then
		local level = UnitLevel(PlayerFrame.unit);
		PlayerLevelText:SetVertexColor(1.0, 0.82, 0.0, 1.0);
		PlayerFrame_UpdateLevelTextAnchor(level);
		PlayerLevelText:SetText(level);
		PlayerFrame_UpdatePartyLeader();
		PlayerFrame_UpdatePvPStatus();
		PlayerFrame_UpdateStatus();
		PlayerFrame_UpdatePlaytime();
		PlayerFrame_UpdateLayout();
	end
end

function PlayerFrame_UpdatePartyLeader()
	if ( UnitIsGroupLeader("player") ) then
		PlayerLeaderIcon:Show()
		PlayerGuideIcon:Hide();
	else
		PlayerLeaderIcon:Hide();
		PlayerGuideIcon:Hide();
	end

	local lootMethod, lootMaster = GetLootMethod();
	if ( lootMaster == 0 and IsInGroup() ) then
		PlayerMasterIcon:Show();
	else
		PlayerMasterIcon:Hide();
	end
end

function PlayerFrame_UpdatePvPStatus()
	local factionGroup, factionName = UnitFactionGroup("player");
	if ( UnitIsPVPFreeForAll("player") ) then
		if ( not PlayerPVPIcon:IsShown() ) then
			PlaySound(SOUNDKIT.IG_PVP_UPDATE);
		end
		PlayerPrestigePortrait:Hide();
		PlayerPrestigeBadge:Hide();
		PlayerPVPIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA");
		PlayerPVPIcon:Show();
		

		-- Setup newbie tooltip
		PlayerPVPIconHitArea.tooltipTitle = PVPFFA;
		PlayerPVPIconHitArea.tooltipText = NEWBIE_TOOLTIP_PVPFFA;
		PlayerPVPIconHitArea:Show();

		PlayerPVPTimerText:Hide();
		PlayerPVPTimerText.timeLeft = nil;
	elseif ( factionGroup and factionGroup ~= "Neutral" and UnitIsPVP("player") ) then
		if ( not PlayerPVPIcon:IsShown() ) then
			PlaySound(SOUNDKIT.IG_PVP_UPDATE);
		end

		
		PlayerPrestigePortrait:Hide();
		PlayerPrestigeBadge:Hide();
		PlayerPVPIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..factionGroup);

		PlayerPVPIcon:Show();

		-- Setup newbie tooltip
		PlayerPVPIconHitArea.tooltipTitle = factionName;
		PlayerPVPIconHitArea.tooltipText = _G["NEWBIE_TOOLTIP_"..strupper(factionGroup)];
		PlayerPVPIconHitArea:Show();
	else
		PlayerPrestigePortrait:Hide();
		PlayerPrestigeBadge:Hide();
		PlayerPVPIcon:Hide();
		PlayerPVPIconHitArea:Hide();

		PlayerPVPTimerText:Hide();
		PlayerPVPTimerText.timeLeft = nil;
	end
end

function PlayerFrame_UpdatePVPTimer()
	if ( IsPVPTimerRunning() ) then
		PlayerPVPTimerText:Show();
		PlayerPVPTimerText.timeLeft = GetPVPTimer();
	else
		PlayerPVPTimerText:Hide();
		PlayerPVPTimerText.timeLeft = nil;
	end
end

function PlayerFrame_OnEvent(self, event, ...)
	UnitFrame_OnEvent(self, event, ...);

	local arg1, arg2, arg3, arg4, arg5 = ...;
	if ( event == "UNIT_LEVEL" ) then
		if ( arg1 == "player" ) then
			PlayerFrame_Update();
		end
	elseif ( event == "UNIT_COMBAT" ) then
		if ( arg1 == self.unit ) then
			CombatFeedback_OnCombatEvent(self, arg2, arg3, arg4, arg5);
		end
	elseif ( event == "UNIT_FACTION" ) then
		if ( arg1 == "player" ) then
			PlayerFrame_UpdatePvPStatus();
		end
	elseif ( event == "PLAYER_ENTERING_WORLD" ) then
		PlayerFrame_ResetPosition(self);
		PlayerFrame_ToPlayerArt(self);
		UnitFrame_SetUnit(self, "player", PlayerFrameHealthBar, PlayerFrameManaBar);
		self.inCombat = nil;
		self.onHateList = nil;
		PlayerFrame_Update();
		PlayerFrame_UpdateStatus();
		PlayerFrame_UpdatePVPTimer();
	elseif ( event == "PLAYER_ENTER_COMBAT" ) then
		self.inCombat = 1;
		PlayerFrame_UpdateStatus();
	elseif ( event == "PLAYER_LEAVE_COMBAT" ) then
		self.inCombat = nil;
		PlayerFrame_UpdateStatus();
	elseif ( event == "PLAYER_REGEN_DISABLED" ) then
		self.onHateList = 1;
		PlayerFrame_UpdateStatus();
	elseif ( event == "PLAYER_REGEN_ENABLED" ) then
		self.onHateList = nil;
		PlayerFrame_UpdateStatus();
	elseif ( event == "PLAYER_UPDATE_RESTING" ) then
		PlayerFrame_UpdateStatus();
	elseif ( event == "PARTY_LEADER_CHANGED" or event == "GROUP_ROSTER_UPDATE" ) then
		PlayerFrame_UpdateGroupIndicator();
		PlayerFrame_UpdatePartyLeader();
		PlayerFrame_UpdateReadyCheck();
	elseif ( event == "PLAYTIME_CHANGED" ) then
		PlayerFrame_UpdatePlaytime();
	elseif ( event == "READY_CHECK" or event == "READY_CHECK_CONFIRM" ) then
		PlayerFrame_UpdateReadyCheck();
	elseif ( event == "READY_CHECK_FINISHED" ) then
		ReadyCheck_Finish(PlayerFrameReadyCheck, DEFAULT_READY_CHECK_STAY_TIME);
	elseif ( event == "UNIT_RUNIC_POWER" and arg1 == "player" ) then
		PlayerFrame_SetRunicPower(UnitPower("player"));
	elseif ( event == "UNIT_ENTERING_VEHICLE" ) then
		if ( arg1 == "player" ) then
			if ( arg2 ) then
				PlayerFrame_AnimateOut(self);
			else
				if ( PlayerFrame.state == "vehicle" ) then
					PlayerFrame_AnimateOut(self);
				end
			end
		end
	elseif ( event == "UNIT_ENTERED_VEHICLE" ) then
		if ( arg1 == "player" ) then
			self.inSeat = true;
			if (UnitInVehicleHidesPetFrame("player")) then
				self.vehicleHidesPet = true;
			end
			PlayerFrame_UpdateArt(self);
		end
	elseif ( event == "UNIT_EXITING_VEHICLE" ) then
		if ( arg1 == "player" ) then
			if ( self.state == "vehicle" ) then
				PlayerFrame_AnimateOut(self);
			else
				self.updatePetFrame = true;
			end
			self.vehicleHidesPet = false;
		end
	elseif ( event == "UNIT_EXITED_VEHICLE" ) then
		if ( arg1 == "player" ) then
			self.inSeat = true;
			PlayerFrame_UpdateArt(self);
		end
	elseif ( event == "PLAYER_FLAGS_CHANGED" ) then
		PlayerFrame_UpdatePVPTimer();
	elseif ( event == "VARIABLES_LOADED" ) then
		PlayerFrame_SetLocked(not PLAYER_FRAME_UNLOCKED);
		if ( PLAYER_FRAME_CASTBARS_SHOWN ) then
			PlayerFrame_AttachCastBar();
		end
	end
end

local function PlayerFrame_AnimPos(self, fraction)
	return "TOPLEFT", UIParent, "TOPLEFT", -19, fraction*140-4;
end

function PlayerFrame_ResetPosition(self)
	CancelAnimations(PlayerFrame);
	self.isAnimatedOut = false;
	UIParent_UpdateTopFramePositions();
	self.inSequence = false;
	PetFrame_Update(PetFrame);
end

local PlayerFrameAnimTable = {
	totalTime = 0.3,
	updateFunc = "SetPoint",
	getPosFunc = PlayerFrame_AnimPos,
	}
function PlayerFrame_AnimateOut(self)
	self.inSeat = false;
	self.animFinished = false;
	self.inSequence = true;
	self.isAnimatedOut = true;
	if ( self:IsUserPlaced() ) then
		PlayerFrame_AnimFinished(PlayerFrame);
	else
		SetUpAnimation(PlayerFrame, PlayerFrameAnimTable, PlayerFrame_AnimFinished, false)
	end
end

function PlayerFrame_AnimFinished(self)
	self.animFinished = true;
	PlayerFrame_UpdateArt(self);
end

function PlayerFrame_IsAnimatedOut(self)
	return self.isAnimatedOut;
end

function PlayerFrame_UpdateArt(self)
	if ( self.inSeat ) then
		if ( self:IsUserPlaced() ) then
			PlayerFrame_SequenceFinished(PlayerFrame);
		elseif ( self.animFinished and self.inSequence ) then
			SetUpAnimation(PlayerFrame, PlayerFrameAnimTable, PlayerFrame_SequenceFinished, true)
		end
		if ( UnitHasVehiclePlayerFrameUI("player") ) then
			PlayerFrame_ToVehicleArt(self, UnitVehicleSkinType("player"));
		else
		PlayerFrame_ToPlayerArt(self);
		end
	elseif ( self.updatePetFrame ) then
		-- leaving a vehicle that didn't change player art
		self.updatePetFrame = false;
		PetFrame_Update(PetFrame);
	end
end

function PlayerFrame_SequenceFinished(self)
	self.isAnimatedOut = false;
	self.inSequence = false;
	PetFrame_Update(PetFrame);
end

function PlayerFrame_ToVehicleArt(self, vehicleType)
	--Swap frame

	PlayerFrame.state = "vehicle";

	UnitFrame_SetUnit(self, "vehicle", PlayerFrameHealthBar, PlayerFrameManaBar);
	UnitFrame_SetUnit(PetFrame, "player", PetFrameHealthBar, PetFrameManaBar);
	PetFrame_Update(PetFrame);
	PlayerFrame_Update();
	BuffFrame_Update();
	ComboFrame_Update(ComboFrame);

	PlayerFrameTexture:Hide();
	if ( vehicleType == "Natural" ) then
		PlayerFrameVehicleTexture:SetTexture("Interface\\Vehicles\\UI-Vehicle-Frame-Organic");
		PlayerFrameFlash:SetTexture("Interface\\Vehicles\\UI-Vehicle-Frame-Organic-Flash");
		PlayerFrameFlash:SetTexCoord(-0.02, 1, 0.07, 0.86);
		PlayerFrameHealthBar:SetWidth(103);
		PlayerFrameHealthBar:SetPoint("TOPLEFT",116,-41);
		PlayerFrameManaBar:SetWidth(103);
		PlayerFrameManaBar:SetPoint("TOPLEFT",116,-52);
	else
		PlayerFrameVehicleTexture:SetTexture("Interface\\Vehicles\\UI-Vehicle-Frame");
		PlayerFrameFlash:SetTexture("Interface\\Vehicles\\UI-Vehicle-Frame-Flash");
		PlayerFrameFlash:SetTexCoord(-0.02, 1, 0.07, 0.86);
		PlayerFrameHealthBar:SetWidth(100);
		PlayerFrameHealthBar:SetPoint("TOPLEFT",119,-41);
		PlayerFrameManaBar:SetWidth(100);
		PlayerFrameManaBar:SetPoint("TOPLEFT",119,-52);
	end
	PlayerFrame_ShowVehicleTexture();

	PlayerName:SetPoint("CENTER",50,23);
	PlayerLeaderIcon:SetPoint("TOPLEFT",44,-10);
	PlayerFrameGroupIndicator:SetPoint("BOTTOMLEFT", PlayerFrame, "TOPLEFT", 97, -13);

	PlayerFrameBackground:SetWidth(114);
	PlayerLevelText:Hide();
end

function PlayerFrame_ToPlayerArt(self)
	--Unswap frame

	PlayerFrame.state = "player";

	UnitFrame_SetUnit(self, "player", PlayerFrameHealthBar, PlayerFrameManaBar);
	UnitFrame_SetUnit(PetFrame, "pet", PetFrameHealthBar, PetFrameManaBar);
	PetFrame_Update(PetFrame);
	PlayerFrame_Update();
	BuffFrame_Update();
	ComboFrame_Update(ComboFrame);

	PlayerFrameTexture:Show();
	PlayerFrame_HideVehicleTexture();
	PlayerName:SetPoint("CENTER",50,19);
	PlayerLeaderIcon:SetPoint("TOPLEFT",44,-10);
	PlayerFrameGroupIndicator:SetPoint("BOTTOMLEFT", PlayerFrame, "TOPLEFT", 97, -20);
	PlayerFrameHealthBar:SetWidth(119);
	PlayerFrameHealthBar:SetPoint("TOPLEFT",106,-41);
	PlayerFrameManaBar:SetWidth(119);
	PlayerFrameManaBar:SetPoint("TOPLEFT",106,-52);
	PlayerFrameBackground:SetWidth(119);
	PlayerLevelText:Show();
end

function PlayerFrame_UpdateVoiceStatus (status)
	PlayerSpeakerFrame:Hide();
end

function PlayerFrame_UpdateReadyCheck ()
	local readyCheckStatus = GetReadyCheckStatus("player");
	if ( readyCheckStatus ) then
		if ( readyCheckStatus == "ready" ) then
			ReadyCheck_Confirm(PlayerFrameReadyCheck, 1);
		elseif ( readyCheckStatus == "notready" ) then
			ReadyCheck_Confirm(PlayerFrameReadyCheck, 0);
		else -- "waiting"
			ReadyCheck_Start(PlayerFrameReadyCheck);
		end
	else
		PlayerFrameReadyCheck:Hide();
	end
end

function PlayerFrame_OnUpdate (self, elapsed)
	if ( PlayerStatusTexture:IsShown() ) then
		local alpha = 255;
		local counter = self.statusCounter + elapsed;
		local sign    = self.statusSign;

		if ( counter > 0.5 ) then
			sign = -sign;
			self.statusSign = sign;
		end
		counter = mod(counter, 0.5);
		self.statusCounter = counter;

		if ( sign == 1 ) then
			alpha = (55  + (counter * 400)) / 255;
		else
			alpha = (255 - (counter * 400)) / 255;
		end
		PlayerStatusTexture:SetAlpha(alpha);
		PlayerStatusGlow:SetAlpha(alpha);
	end

	if ( PlayerPVPTimerText.timeLeft ) then
		PlayerPVPTimerText.timeLeft = PlayerPVPTimerText.timeLeft - elapsed*1000;
		local timeLeft = PlayerPVPTimerText.timeLeft;
		if ( timeLeft < 0 ) then
			PlayerPVPTimerText:Hide()
		end
		PlayerPVPTimerText:SetFormattedText(SecondsToTimeAbbrev(floor(timeLeft/1000)));
	else
		PlayerPVPTimerText:Hide();
	end

	CombatFeedback_OnUpdate(self, elapsed);
end

function PlayerFrame_OnReceiveDrag ()
	if ( CursorHasItem() ) then
		AutoEquipCursorItem();
	end
end

function PlayerFrame_UpdateStatus()
	if ( UnitHasVehiclePlayerFrameUI("player") ) then
		PlayerStatusTexture:Hide()
		PlayerRestIcon:Hide()
		PlayerAttackIcon:Hide()
		PlayerRestGlow:Hide()
		PlayerAttackGlow:Hide()
		PlayerStatusGlow:Hide()
		PlayerAttackBackground:Hide()
	elseif ( IsResting() ) then
		PlayerStatusTexture:SetVertexColor(1.0, 0.88, 0.25, 1.0);
		PlayerStatusTexture:Show();
		PlayerRestIcon:Show();
		PlayerAttackIcon:Hide();
		PlayerRestGlow:Show();
		PlayerAttackGlow:Hide();
		PlayerStatusGlow:Show();
		PlayerAttackBackground:Hide();
	elseif ( PlayerFrame.inCombat ) then
		PlayerStatusTexture:SetVertexColor(1.0, 0.0, 0.0, 1.0);
		PlayerStatusTexture:Show();
		PlayerAttackIcon:Show();
		PlayerRestIcon:Hide();
		PlayerAttackGlow:Show();
		PlayerRestGlow:Hide();
		PlayerStatusGlow:Show();
		PlayerAttackBackground:Show();
	elseif ( PlayerFrame.onHateList ) then
		PlayerAttackIcon:Show();
		PlayerRestIcon:Hide();
		PlayerStatusGlow:Hide();
		PlayerAttackBackground:Hide();
	else
		PlayerStatusTexture:Hide();
		PlayerRestIcon:Hide();
		PlayerAttackIcon:Hide();
		PlayerStatusGlow:Hide();
		PlayerAttackBackground:Hide();
	end
end

function PlayerFrame_UpdateGroupIndicator()
	PlayerFrameGroupIndicator:Hide();
	local name, rank, subgroup;
	if ( not IsInRaid() ) then
		PlayerFrameGroupIndicator:Hide();
		return;
	end
	local numGroupMembers = GetNumGroupMembers();
	for i=1, MAX_RAID_MEMBERS do
		if ( i <= numGroupMembers ) then
			name, rank, subgroup = GetRaidRosterInfo(i);
			-- Set the player's group number indicator
			if ( name == UnitName("player") ) then
				PlayerFrameGroupIndicatorText:SetText(GROUP.." "..subgroup);
				PlayerFrameGroupIndicator:SetWidth(PlayerFrameGroupIndicatorText:GetWidth()+40);
				PlayerFrameGroupIndicator:Show();
			end
		end
	end
end

function PlayerFrame_UpdatePlaytime()
	if ( PartialPlayTime() ) then
		PlayerPlayTimeIcon:SetTexture("Interface\\CharacterFrame\\UI-Player-PlayTimeTired");
		PlayerPlayTime.tooltip = format(PLAYTIME_TIRED, REQUIRED_REST_HOURS - floor(GetBillingTimeRested()/60));
		PlayerPlayTime:Show();
	elseif ( NoPlayTime() ) then
		PlayerPlayTimeIcon:SetTexture("Interface\\CharacterFrame\\UI-Player-PlayTimeUnhealthy");
		PlayerPlayTime.tooltip = format(PLAYTIME_UNHEALTHY, REQUIRED_REST_HOURS - floor(GetBillingTimeRested()/60));
		PlayerPlayTime:Show();
	else
		PlayerPlayTime:Hide();
	end
end

function PlayerFrame_SetupDeathKnightLayout ()
	PlayerFrame:SetHitRectInsets(0,0,0,33);
end

function PlayerFrameMultiGroupFrame_OnLoad(self)
	self:RegisterEvent("GROUP_ROSTER_UPDATE");
	self:RegisterEvent("UPDATE_CHAT_COLOR");
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
end

function PlayerFrameMultiGroupFrame_OnEvent(self, event, ...)
	if ( event == "GROUP_ROSTER_UPDATE" ) then
		if ( IsInGroup(LE_PARTY_CATEGORY_HOME) and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) ) then
			self:Show();
		else
			self:Hide();
		end
	elseif ( event == "UPDATE_CHAT_COLOR" ) then
		local public = ChatTypeInfo["INSTANCE_CHAT"];
		local private = ChatTypeInfo["PARTY"];
		self.HomePartyIcon:SetVertexColor(private.r, private.g, private.b);
		self.InstancePartyIcon:SetVertexColor(public.r, public.g, public.b);
	end
end

function PlayerFrameMultiGroupframe_OnEnter(self)
	GameTooltip_SetDefaultAnchor(GameTooltip, self);
	self.homePlayers = GetHomePartyInfo(self.homePlayers);

	if ( IsInRaid(LE_PARTY_CATEGORY_HOME) ) then
		GameTooltip:SetText(PLAYER_IN_MULTI_GROUP_RAID_MESSAGE, nil, nil, nil, nil, true);
		GameTooltip:AddLine(format(MEMBER_COUNT_IN_RAID_LIST, #self.homePlayers + 1), 1, 1, 1, true);
	else
		GameTooltip:AddLine(PLAYER_IN_MULTI_GROUP_PARTY_MESSAGE, 1, 1, 1, true);
		local playerList = self.homePlayers[1] or "";
		for i=2, #self.homePlayers do
			playerList = playerList..PLAYER_LIST_DELIMITER..self.homePlayers[i];
		end
		GameTooltip:AddLine(format(MEMBERS_IN_PARTY_LIST, playerList));
	end
	GameTooltip:Show();
end

CustomClassLayouts = {
	["DEATHKNIGHT"] = PlayerFrame_SetupDeathKnightLayout,
}

local layoutUpdated = false;

function PlayerFrame_UpdateLayout ()
	if ( layoutUpdated ) then
		return;
	end
	layoutUpdated = true;

	local _, class = UnitClass("player");

	if ( CustomClassLayouts[class] ) then
		CustomClassLayouts[class]();
	end
end

local RUNICPOWERBARHEIGHT = 63;
local RUNICPOWERBARWIDTH = 64;

local RUNICGLOW_FADEALPHA = .050
local RUNICGLOW_MINALPHA = .40
local RUNICGLOW_MAXALPHA = .80
local RUNICGLOW_THROBINTERVAL = .8;

RUNICGLOW_FINISHTHROBANDHIDE = false;
local RUNICGLOW_THROBSTART = 0;

function PlayerFrame_SetRunicPower (runicPower)
	PlayerFrameRunicPowerBar:SetHeight(RUNICPOWERBARHEIGHT * (runicPower / 100));
	PlayerFrameRunicPowerBar:SetTexCoord(0, 1, (1 - (runicPower / 100)), 1);

	if ( runicPower >= 90 ) then
		-- Oh,  God help us for these function and variable names.
		RUNICGLOW_FINISHTHROBANDHIDE = false;
		if ( not PlayerFrameRunicPowerGlow:IsShown() ) then
			PlayerFrameRunicPowerGlow:Show();
		end
		PlayerFrameRunicPowerGlow:GetParent():SetScript("OnUpdate", DeathKnniggetThrobFunction);
	elseif ( PlayerFrameRunicPowerGlow:GetParent():GetScript("OnUpdate") ) then
		RUNICGLOW_FINISHTHROBANDHIDE = true;
	else
		PlayerFrameRunicPowerGlow:Hide();
	end
end

local firstFadeIn = true;
function DeathKnniggetThrobFunction (self, elapsed)
	if ( RUNICGLOW_THROBSTART == 0 ) then
		RUNICGLOW_THROBSTART = GetTime();
	elseif ( not RUNICGLOW_FINISHTHROBANDHIDE ) then
		local interval = RUNICGLOW_THROBINTERVAL - math.abs( .9 - (UnitPower("player") / 100));
		local animTime = GetTime() - RUNICGLOW_THROBSTART;
		if ( animTime >= interval ) then
			-- Fading out
			PlayerFrameRunicPowerGlow:SetAlpha(math.max(RUNICGLOW_MINALPHA, math.min(RUNICGLOW_MAXALPHA, RUNICGLOW_MAXALPHA * interval/animTime)));
			if ( animTime >= interval * 2 ) then
				self.timeSinceThrob = 0;
				RUNICGLOW_THROBSTART = GetTime();
			end
			firstFadeIn = false;
		else
			-- Fading in
			if ( firstFadeIn ) then
				PlayerFrameRunicPowerGlow:SetAlpha(math.max(RUNICGLOW_FADEALPHA, math.min(RUNICGLOW_MAXALPHA, RUNICGLOW_MAXALPHA * animTime/interval)));
			else
				PlayerFrameRunicPowerGlow:SetAlpha(math.max(RUNICGLOW_MINALPHA, math.min(RUNICGLOW_MAXALPHA, RUNICGLOW_MAXALPHA * animTime/interval)));
			end
		end
	elseif ( RUNICGLOW_FINISHTHROBANDHIDE ) then
		local currentAlpha = PlayerFrameRunicPowerGlow:GetAlpha();
		local animTime = GetTime() - RUNICGLOW_THROBSTART;
		local interval = RUNICGLOW_THROBINTERVAL;
		firstFadeIn = true;

		if ( animTime >= interval ) then
			-- Already fading out, just keep fading out.
			local alpha = math.min(PlayerFrameRunicPowerGlow:GetAlpha(), RUNICGLOW_MAXALPHA * (interval/(animTime*(animTime/2))));

			PlayerFrameRunicPowerGlow:SetAlpha(alpha);
			if ( alpha <= RUNICGLOW_FADEALPHA ) then
				self.timeSinceThrob = 0;
				RUNICGLOW_THROBSTART = 0;
				PlayerFrameRunicPowerGlow:Hide();
				self:SetScript("OnUpdate", nil);
				RUNICGLOW_FINISHTHROBANDHIDE = false;
				return;
			end
		else
			-- Was fading in, start fading out
			animTime = interval;
		end
	end
end



function PlayerFrame_ShowVehicleTexture()
	PlayerFrameVehicleTexture:Show();

	local _, class = UnitClass("player");
	if ( PlayerFrame.classPowerBar ) then
		PlayerFrame.classPowerBar:Hide();
	elseif ( class == "SHAMAN" ) then
		TotemFrame:Hide();
	elseif ( class == "DEATHKNIGHT" ) then
		RuneFrame:Hide();
	elseif ( class == "PRIEST" and PriestBarFrame) then
		PriestBarFrame:Hide();
	end
end


function PlayerFrame_HideVehicleTexture()
	PlayerFrameVehicleTexture:Hide();

	local _, class = UnitClass("player");
	if ( PlayerFrame.classPowerBar ) then
		PlayerFrame.classPowerBar:Setup();
	elseif ( class == "SHAMAN" ) then
		if (TotemFrame) then
			TotemFrame:Update();
		end
	elseif ( class == "DEATHKNIGHT" ) then
		RuneFrame:Show();
	elseif ( class == "PRIEST" and PriestBarFrame) then
		PriestBarFrame:CheckAndShow();
	end
end

function PlayerFrame_OnDragStart(self)
	self:StartMoving();
	self:SetUserPlaced(true);
	self:SetClampedToScreen(true);
end

function PlayerFrame_OnDragStop(self)
	self:StopMovingOrSizing();
end

function PlayerFrame_SetLocked(locked)
	PLAYER_FRAME_UNLOCKED = not locked;
	if ( locked ) then
		PlayerFrame:RegisterForDrag();	--Unregister all buttons.
	else
		PlayerFrame:RegisterForDrag("LeftButton");
	end
end

function PlayerFrame_ResetUserPlacedPosition()
	PlayerFrame:ClearAllPoints();
	PlayerFrame:SetUserPlaced(false);
	PlayerFrame:SetClampedToScreen(false);
	PlayerFrame_SetLocked(true);
	UIParent_UpdateTopFramePositions();
end

--
-- Functions for having the cast bar underneath the player frame
--

function PlayerFrame_AttachCastBar()
	local castBar = CastingBarFrame;
	local petCastBar = PetCastingBarFrame;
	-- player
	castBar.ignoreFramePositionManager = true;
	castBar:SetAttribute("ignoreFramePositionManager", true);
	CastingBarFrame_SetLook(castBar, "UNITFRAME");
	castBar:ClearAllPoints();
	castBar:SetPoint("LEFT", PlayerFrame, 78, 0);
	-- pet
	CastingBarFrame_SetLook(petCastBar, "UNITFRAME");
	petCastBar:SetWidth(150);
	petCastBar:SetHeight(10);
	petCastBar:ClearAllPoints();
	petCastBar:SetPoint("TOP", castBar, "TOP", 0, 0);

	PlayerFrame_AdjustAttachments();
	UIParent_ManageFramePositions();
end

function PlayerFrame_DetachCastBar()
	local castBar = CastingBarFrame;
	local petCastBar = PetCastingBarFrame;
	-- player
	castBar.ignoreFramePositionManager = nil;
	castBar:SetAttribute("ignoreFramePositionManager", false);
	CastingBarFrame_SetLook(castBar, "CLASSIC");
	castBar:ClearAllPoints();
	-- pet
	CastingBarFrame_SetLook(petCastBar, "CLASSIC");
	petCastBar:SetWidth(195);
	petCastBar:SetHeight(13);
	petCastBar:ClearAllPoints();
	petCastBar:SetPoint("BOTTOM", castBar, "TOP", 0, 12);

	UIParent_ManageFramePositions();
end

function PlayerFrame_AdjustAttachments()
	if ( not PLAYER_FRAME_CASTBARS_SHOWN ) then
		return;
	end
	if ( PetFrame and PetFrame:IsShown() ) then
		CastingBarFrame:SetPoint("TOP", PetFrame, "BOTTOM", 0, -4);
	elseif ( TotemFrame and TotemFrame:IsShown() ) then
		CastingBarFrame:SetPoint("TOP", TotemFrame, "BOTTOM", 0, 2);
	else
		local _, class = UnitClass("player");
		if ( class == "PALADIN" ) then
			CastingBarFrame:SetPoint("TOP", PlayerFrame, "BOTTOM", 0, -6);
		elseif ( class == "DRUID" ) then
		CastingBarFrame:SetPoint("TOP", PlayerFrame, "BOTTOM", 0, 10);
		elseif ( class == "PRIEST" and PriestBarFrame and PriestBarFrame:IsShown() ) then
			CastingBarFrame:SetPoint("TOP", PlayerFrame, "BOTTOM", 0, -2);
		elseif ( class == "DEATHKNIGHT" or class == "WARLOCK" ) then
			CastingBarFrame:SetPoint("TOP", PlayerFrame, "BOTTOM", 0, 4);
		elseif ( class == "MONK" ) then
			CastingBarFrame:SetPoint("TOP", PlayerFrame, "BOTTOM", 0, -1);
		else
			CastingBarFrame:SetPoint("TOP", PlayerFrame, "BOTTOM", 0, 10);
		end
	end
end
