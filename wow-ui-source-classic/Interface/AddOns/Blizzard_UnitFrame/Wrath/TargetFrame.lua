MAX_COMBO_POINTS = 5;
MAX_TARGET_DEBUFFS = 16;
MAX_TARGET_BUFFS = 32;
MAX_BOSS_FRAMES = 5;

TARGET_FRAME_BUFFS_ON_TOP = TARGET_FRAME_BUFFS_ON_TOP or nil;
TARGET_FRAME_UNLOCKED = TARGET_FRAME_UNLOCKED or nil;

-- aura positioning constants
local AURA_START_X = 5;
local AURA_START_Y = 32;
local AURA_OFFSET_Y = 1;
local LARGE_AURA_SIZE = 21;
local SMALL_AURA_SIZE = 17;
local AURA_ROW_WIDTH = 122;
local TOT_AURA_ROW_WIDTH = 101;
local NUM_TOT_AURA_ROWS = 2;	-- TODO: replace with TOT_AURA_ROW_HEIGHT functionality if this becomes a problem

-- focus frame scales
local LARGE_FOCUS_SCALE = 1;
local SMALL_FOCUS_SCALE = 0.75;
local SMALL_FOCUS_UPSCALE = 1.333;

local PLAYER_UNITS = {
	player = true,
	vehicle = true,
	pet = true,
};

CVarCallbackRegistry:SetCVarCachable("showTargetOfTarget");

function TargetFrame_OnLoad(self, unit, menuFunc)
	self.HealthBar.LeftText = self.textureFrame.HealthBarTextLeft;
	self.HealthBar.RightText = self.textureFrame.HealthBarTextRight;
	self.PowerBar.LeftText = self.textureFrame.ManaBarTextLeft;
	self.PowerBar.RightText = self.textureFrame.ManaBarTextRight;

	self.statusCounter = 0;
	self.statusSign = -1;
	self.unitHPPercent = 1;

	local thisName = self:GetName();
	self.borderTexture = _G[thisName.."TextureFrameTexture"];
	self.highLevelTexture = _G[thisName.."TextureFrameHighLevelTexture"];
	self.pvpIcon = _G[thisName.."TextureFramePVPIcon"];
	self.prestigePortrait = _G[thisName.."TextureFramePrestigePortrait"];
	self.prestigeBadge = _G[thisName.."TextureFramePrestigeBadge"];
	self.leaderIcon = _G[thisName.."TextureFrameLeaderIcon"];
	self.raidTargetIcon = _G[thisName.."TextureFrameRaidTargetIcon"];
	self.questIcon = _G[thisName.."TextureFrameQuestIcon"];
	self.levelText = _G[thisName.."TextureFrameLevelText"];
	self.deadText = _G[thisName.."TextureFrameDeadText"];
	self.unconsciousText = _G[thisName.."TextureFrameUnconsciousText"];
	self.petBattleIcon = _G[thisName.."TextureFramePetBattleIcon"];
	self.TOT_AURA_ROW_WIDTH = TOT_AURA_ROW_WIDTH;
	-- set simple frame
	if ( not self.showLevel ) then
		self.highLevelTexture:Hide();
		self.levelText:Hide();
	end
	-- set threat frame
	local threatFrame;
	if ( self.showThreat ) then
		threatFrame = _G[thisName.."Flash"];
	end
	-- set portrait frame
	local portraitFrame;
	if ( self.showPortrait ) then
		portraitFrame = _G[thisName.."Portrait"];
	end

	local healthBar = self.HealthBar;
	local manaBar = self.PowerBar;
	UnitFrame_Initialize(self, unit, self.textureFrame.Name, portraitFrame,
						healthBar,
						self.textureFrame.HealthBarText,
						manaBar,
						self.textureFrame.ManaBarText,
	                    threatFrame, "player", _G[thisName.."NumericalThreat"],
						healthBar.MyHealPredictionBar,
						healthBar.OtherHealPredictionBar,
						healthBar.TotalAbsorbBar, healthBar.TotalAbsorbBarOverlay,
						self.textureFrame.overAbsorbGlow, self.textureFrame.overHealAbsorbGlow,
						healthBar.HealAbsorbBar, healthBar.HealAbsorbBarLeftShadow,
						healthBar.HealAbsorbBarRightShadow, nil);

	TargetFrame_Update(self);
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("UNIT_HEALTH");
	if ( self.showLevel ) then
		self:RegisterEvent("UNIT_LEVEL");
	end
	self:RegisterEvent("UNIT_FACTION");
	if ( self.showClassification ) then
		self:RegisterEvent("UNIT_CLASSIFICATION_CHANGED");
	end
	if ( self.showLeader ) then
		self:RegisterEvent("PLAYER_FLAGS_CHANGED");
	end
	self:RegisterEvent("GROUP_ROSTER_UPDATE");
	self:RegisterEvent("RAID_TARGET_UPDATE");
	self:RegisterUnitEvent("UNIT_AURA", unit);
	self:RegisterUnitEvent("UNIT_TARGET", unit);

	SecureUnitButton_OnLoad(self, self.unit, menuFunc);

	CVarCallbackRegistry:RegisterCVarChangedCallback(TargetFrame_OnCVarChanged, self);
end

function TargetFrame_OnCVarChanged (self, cvar, cvarValue)
	if( cvar == "showTargetOfTarget" and self.totFrame ) then
		TargetofTarget_Update(self.totFrame);
	end
end

function TargetFrame_Update (self)
	-- This check is here so the frame will hide when the target goes away
	-- even if some of the functions below are hooked by addons.
	if ( not UnitExists(self.unit) and not ShowBossFrameWhenUninteractable(self.unit) ) then
		self:Hide();
	else
		self:Show();

		-- Moved here to avoid taint from functions below
		if ( self.totFrame ) then
			TargetofTarget_Update(self.totFrame);
			TargetofTarget_UpdateDebuffs(self.totFrame);
		end

		UnitFrame_Update(self);
		if ( self.showLevel ) then
			TargetFrame_CheckLevel(self);
		end
		TargetFrame_CheckFaction(self);
		if ( self.showClassification ) then
			TargetFrame_CheckClassification(self);
		end
		TargetFrame_CheckDead(self);
		if ( self.showLeader ) then
			if ( UnitLeadsAnyGroup(self.unit) ) then
				self.leaderIcon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon");
				self.leaderIcon:SetTexCoord(0, 1, 0, 1);
				self.leaderIcon:Show();
			else
				self.leaderIcon:Hide();
			end
		end
		TargetFrame_UpdateAuras(self);
		if ( self.portrait ) then
			self.portrait:SetAlpha(1.0);
		end
		TargetFrame_CheckBattlePet(self);
		if ( self.petBattleIcon ) then
			self.petBattleIcon:SetAlpha(1.0);
		end
	end
end

function TargetFrame_OnEvent (self, event, ...)
	UnitFrame_OnEvent(self, event, ...);

	local arg1 = ...;
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		TargetFrame_Update(self);
	elseif ( event == "PLAYER_TARGET_CHANGED" ) then
		-- Moved here to avoid taint from functions below
		TargetFrame_Update(self);
		TargetFrame_UpdateRaidTargetIcon(self);

		if ( UnitExists(self.unit) and not C_PlayerInteractionManager.IsReplacingUnit()) then
			if ( UnitIsEnemy(self.unit, "player") ) then
				PlaySound(SOUNDKIT.IG_CREATURE_AGGRO_SELECT);
			elseif ( UnitIsFriend("player", self.unit) ) then
				PlaySound(SOUNDKIT.IG_CHARACTER_NPC_SELECT);
			else
				PlaySound(SOUNDKIT.IG_CREATURE_NEUTRAL_SELECT);
			end
		end
	elseif ( event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" ) then
		for i = 1, MAX_BOSS_FRAMES do
			TargetFrame_Update(_G["Boss"..i.."TargetFrame"]);
			TargetFrame_UpdateRaidTargetIcon(_G["Boss"..i.."TargetFrame"]);
		end
		UIParent_ManageFramePositions();
	elseif ( event == "UNIT_TARGETABLE_CHANGED" and arg1 == self.unit) then
		TargetFrame_Update(self);
		TargetFrame_UpdateRaidTargetIcon(self);
		UIParent_ManageFramePositions();
	elseif ( event == "UNIT_HEALTH" ) then
		if ( arg1 == self.unit ) then
			TargetFrame_CheckDead(self);
		end
	elseif ( event == "UNIT_LEVEL" ) then
		if ( arg1 == self.unit ) then
			TargetFrame_CheckLevel(self);
		end
	elseif ( event == "UNIT_FACTION" ) then
		if ( arg1 == self.unit or arg1 == "player" ) then
			TargetFrame_CheckFaction(self);
			TargetFrame_UpdateAuras(self);
			if ( self.showLevel ) then
				TargetFrame_CheckLevel(self);
			end
		end
	elseif ( event == "UNIT_CLASSIFICATION_CHANGED" ) then
		if ( arg1 == self.unit ) then
			TargetFrame_CheckClassification(self);
		end
	elseif ( event == "UNIT_AURA" ) then
		if ( arg1 == self.unit ) then
			TargetFrame_UpdateAuras(self);
		end
	elseif (event == "UNIT_TARGET") then
		if (self.totFrame) then
			TargetofTarget_Update(self.totFrame);
			TargetofTarget_UpdateDebuffs(self.totFrame);
		end
	elseif ( event == "PLAYER_FLAGS_CHANGED" ) then
		if ( arg1 == self.unit ) then
			if ( UnitLeadsAnyGroup(self.unit) ) then
				self.leaderIcon:Show();
			else
				self.leaderIcon:Hide();
			end
		end
	elseif ( event == "GROUP_ROSTER_UPDATE" ) then
		TargetFrame_Update(self);
		if (self.unit == "focus") then
			-- If this is the focus frame, clear focus if the unit no longer exists
			if (not UnitExists(self.unit)) then
				ClearFocus();
			end
		else
			if ( self.totFrame ) then
				TargetofTarget_Update(self.totFrame);
				TargetofTarget_UpdateDebuffs(self.totFrame);
			end
			TargetFrame_CheckFaction(self);
		end
	elseif ( event == "RAID_TARGET_UPDATE" ) then
		TargetFrame_UpdateRaidTargetIcon(self);
	elseif ( event == "PLAYER_FOCUS_CHANGED" ) then
		if ( UnitExists(self.unit) ) then
			self:Show();
			TargetFrame_Update(self);
			TargetFrame_UpdateRaidTargetIcon(self);
		else
			self:Hide();
		end
	end
end

function TargetFrame_OnVariablesLoaded()
	TargetFrame_SetLocked(not TARGET_FRAME_UNLOCKED);
	TargetFrame_UpdateBuffsOnTop();

	FocusFrame:SetSmallSize(not GetCVarBool("fullSizeFocusFrame"));
	FocusFrame_UpdateBuffsOnTop();
end

function TargetFrame_OnHide (self)
	PlaySound(SOUNDKIT.INTERFACE_SOUND_LOST_TARGET_UNIT);
end

function TargetFrame_CheckLevel (self)
	local targetEffectiveLevel = UnitLevel(self.unit);

	if ( UnitIsCorpse(self.unit) ) then
		self.levelText:Hide();
		self.highLevelTexture:Show();
	elseif (UnitIsWildBattlePet(self.unit) or UnitIsBattlePetCompanion(self.unit)) then
		local petLevel = UnitBattlePetLevel(self.unit);
		self.levelText:SetVertexColor(1.0, 0.82, 0.0);
		self.levelText:SetText(petLevel);
		self.levelText:Show();
		self.highLevelTexture:Hide();
	elseif ( targetEffectiveLevel > 0 ) then
		-- Normal level target
		self.levelText:SetText(targetEffectiveLevel);
		-- Color level number
		if ( UnitCanAttack("player", self.unit) ) then
			local color = GetCreatureDifficultyColor(targetEffectiveLevel);
			self.levelText:SetVertexColor(color.r, color.g, color.b);
		else
			self.levelText:SetVertexColor(1.0, 0.82, 0.0);
		end

		if ( self.isBossFrame ) then
			BossTargetFrame_UpdateLevelTextAnchor(self, targetEffectiveLevel);
		else
			TargetFrame_UpdateLevelTextAnchor(self, targetEffectiveLevel);
		end

		self.levelText:Show();
		self.highLevelTexture:Hide();
	else
		-- Target is too high level to tell
		self.levelText:Hide();
		self.highLevelTexture:Show();
	end
end

--This is overwritten in LocalizationPost for different languages.
function TargetFrame_UpdateLevelTextAnchor (self, targetLevel)
	if ( targetLevel >= 100 ) then
		self.levelText:SetPoint("CENTER", 62, -16);
	else
		self.levelText:SetPoint("CENTER", 63, -16);
	end
end

--This is overwritten in LocalizationPost for different languages.
function BossTargetFrame_UpdateLevelTextAnchor (self, targetLevel)
	if ( targetLevel >= 100 ) then
		self.levelText:SetPoint("CENTER", 11, -16);
	else
		self.levelText:SetPoint("CENTER", 12, -16);
	end
end

function TargetFrame_CheckFaction (self)
	if ( not UnitPlayerControlled(self.unit) and UnitIsTapDenied(self.unit) ) then
		self.nameBackground:SetVertexColor(0.5, 0.5, 0.5);
		if ( self.portrait ) then
			self.portrait:SetVertexColor(0.5, 0.5, 0.5);
		end
	else
		self.nameBackground:SetVertexColor(UnitSelectionColor(self.unit));
		if ( self.portrait ) then
			self.portrait:SetVertexColor(1.0, 1.0, 1.0);
		end
	end

	if ( self.showPVP ) then
		local factionGroup = UnitFactionGroup(self.unit);
		if ( UnitIsPVPFreeForAll(self.unit) ) then
				self.prestigePortrait:Hide();
				self.prestigeBadge:Hide();
				self.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA");
				self.pvpIcon:Show();
		elseif ( factionGroup and factionGroup ~= "Neutral" and UnitIsPVP(self.unit) ) then
				self.prestigePortrait:Hide();
				self.prestigeBadge:Hide();
				self.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..factionGroup);
				self.pvpIcon:Show();
		else
			self.prestigePortrait:Hide();
			self.prestigeBadge:Hide();
			self.pvpIcon:Hide();
		end
	end
end

function TargetFrame_CheckBattlePet(self)
	if ( UnitIsWildBattlePet(self.unit) or UnitIsBattlePetCompanion(self.unit) ) then
		local petType = UnitBattlePetType(self.unit);
		self.petBattleIcon:SetTexture("Interface\\TargetingFrame\\PetBadge-"..PET_TYPE_SUFFIX[petType]);
		self.petBattleIcon:Show();
	else
		self.petBattleIcon:Hide();
	end
end


function TargetFrame_CheckClassification (self, forceNormalTexture)
	local classification = UnitClassification(self.unit);
	self.nameBackground:Show();
	self.manabar.pauseUpdates = false;
	self.manabar:Show();
	TextStatusBar_UpdateTextString(self.manabar);
	self.threatIndicator:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Flash");

	if ( forceNormalTexture ) then
		self.borderTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame");
	elseif ( classification == "minus" ) then
		self.borderTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Minus");
		self.nameBackground:Hide();
		self.manabar.pauseUpdates = true;
		self.manabar:Hide();
		self.manabar.TextString:Hide();
		self.manabar.LeftText:Hide();
		self.manabar.RightText:Hide();
		forceNormalTexture = true;
	elseif ( classification == "worldboss" or classification == "elite" ) then
		self.borderTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Elite");
	elseif ( classification == "rareelite" ) then
		self.borderTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare-Elite");
	elseif ( classification == "rare" ) then
		self.borderTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare");
	else
		self.borderTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame");
		forceNormalTexture = true;
	end

	if ( forceNormalTexture ) then
		self.haveElite = nil;
		if ( classification == "minus" ) then
			self.Background:SetSize(119,12);
			self.Background:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 7, 47);
		else
			self.Background:SetSize(119,25);
			self.Background:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 7, 35);
		end
		if ( self.threatIndicator ) then
			if ( classification == "minus" ) then
				self.threatIndicator:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Minus-Flash");
				self.threatIndicator:SetTexCoord(0, 1, 0, 1);
				self.threatIndicator:SetWidth(256);
				self.threatIndicator:SetHeight(128);
				self.threatIndicator:SetPoint("TOPLEFT", self, "TOPLEFT", -24, 0);
			else
				self.threatIndicator:SetTexCoord(0, 0.9453125, 0, 0.181640625);
				self.threatIndicator:SetWidth(242);
				self.threatIndicator:SetHeight(93);
				self.threatIndicator:SetPoint("TOPLEFT", self, "TOPLEFT", -24, 0);
			end
		end
	else
		self.haveElite = true;
		TargetFrameBackground:SetSize(119,41);
		self.Background:SetSize(119,25);
		self.Background:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 7, 35);
		if ( self.threatIndicator ) then
			self.threatIndicator:SetTexCoord(0, 0.9453125, 0.181640625, 0.400390625);
			self.threatIndicator:SetWidth(242);
			self.threatIndicator:SetHeight(112);
			self.threatIndicator:SetPoint("TOPLEFT", self, "TOPLEFT", -22, 9);
		end
	end

	--[[if (self.questIcon) then
		if (UnitIsQuestBoss(self.unit)) then
			self.questIcon:Show();
		else
			self.questIcon:Hide();
		end
	end]]
end

function TargetFrame_CheckDead (self)
	if ( (UnitHealth(self.unit) <= 0) and UnitIsConnected(self.unit) ) then
		if ( UnitIsUnconscious(self.unit) ) then
			self.unconsciousText:Show();
			self.deadText:Hide();
		else
			self.unconsciousText:Hide();
			self.deadText:Show();
		end
	else
		self.deadText:Hide();
		self.unconsciousText:Hide();
	end
end

function TargetFrame_OnUpdate (self, elapsed)
	if ( self.totFrame) then
		if ( self.totFrame:IsShown() ~= UnitExists(self.totFrame.unit) ) then
			TargetofTarget_Update(self.totFrame);
		end
		TargetofTarget_UpdateDebuffs(self.totFrame);
	end

	self.elapsed = (self.elapsed or 0) + elapsed;
	if ( self.elapsed > 0.5 ) then
		self.elapsed = 0;
		UnitFrame_UpdateThreatIndicator(self.threatIndicator, self.threatNumericIndicator, self.feedbackUnit);
	end
end

local largeBuffList = {};
local largeDebuffList = {};
local function ShouldAuraBeLarge(caster)
	if not caster then
		return false;
	end

	for token, value in pairs(PLAYER_UNITS) do
		if UnitIsUnit(caster, token) or UnitIsOwnerOrControllerOfUnit(token, caster) then
			return value;
		end
	end
end

function TargetFrame_UpdateAuras (self)
	local frame, frameName;
	local frameIcon, frameCount, frameCooldown;
	local numBuffs = 0;
	local playerIsTarget = UnitIsUnit(PlayerFrame.unit, self.unit);
	local selfName = self:GetName();
	local canAssist = UnitCanAssist("player", self.unit);

	for i = 1, MAX_TARGET_BUFFS do
        local buffName, icon, count, debuffType, duration, expirationTime, caster, canStealOrPurge, _ , spellId, _, _, casterIsPlayer, nameplateShowAll = UnitBuff(self.unit, i, nil);
        if (buffName) then
            frameName = selfName.."Buff"..(i);
            frame = _G[frameName];
            if ( not frame ) then
                if ( not icon ) then
                    break;
                else
                    frame = CreateFrame("Button", frameName, self, "TargetBuffFrameTemplate");
                    frame.unit = self.unit;
                end
            end
            if ( icon and ( not self.maxBuffs or i <= self.maxBuffs ) ) then
                frame:SetID(i);

                -- set the icon
                frameIcon = _G[frameName.."Icon"];
                frameIcon:SetTexture(icon);

                -- set the count
                frameCount = _G[frameName.."Count"];
                if ( count > 1 and self.showAuraCount ) then
                    frameCount:SetText(count);
                    frameCount:Show();
                else
                    frameCount:Hide();
                end

                -- Handle cooldowns
                frameCooldown = _G[frameName.."Cooldown"];
                CooldownFrame_Set(frameCooldown, expirationTime - duration, duration, duration > 0, true);

                -- Show stealable frame if the target is not the current player and the buff is stealable.
                local frameStealable = _G[frameName.."Stealable"];
                if ( not playerIsTarget and canStealOrPurge ) then
                    frameStealable:Show();
                else
                    frameStealable:Hide();
                end

                -- set the buff to be big if the buff is cast by the player or his pet
				numBuffs = numBuffs + 1;
                largeBuffList[numBuffs] = ShouldAuraBeLarge(caster);

                frame:ClearAllPoints();
                frame:Show();
            else
                frame:Hide();
            end
        else
            break;
        end
	end

	for i = numBuffs + 1, MAX_TARGET_BUFFS do
		frame = _G[selfName.."Buff"..i];
		if ( frame ) then
			frame:Hide();
		else
			break;
		end
	end

	local color;
	local frameBorder;
	local numDebuffs = 0;

	local frameNum = 1;
	local index = 1;

	local maxDebuffs = self.maxDebuffs or MAX_TARGET_DEBUFFS;
	while ( frameNum <= maxDebuffs and index <= maxDebuffs ) do
	    local debuffName, icon, count, debuffType, duration, expirationTime, caster, _, _, _, _, _, casterIsPlayer, nameplateShowAll = UnitDebuff(self.unit, index, "INCLUDE_NAME_PLATE_ONLY");
		if ( debuffName ) then
			if ( TargetFrame_ShouldShowDebuffs(self.unit, caster, nameplateShowAll, casterIsPlayer) ) then
				frameName = selfName.."Debuff"..frameNum;
				frame = _G[frameName];
				if ( icon ) then
					if ( not frame ) then
						frame = CreateFrame("Button", frameName, self, "TargetDebuffFrameTemplate");
						frame.unit = self.unit;
					end
					frame:SetID(index);

					-- set the icon
					frameIcon = _G[frameName.."Icon"];
					frameIcon:SetTexture(icon);

					-- set the count
					frameCount = _G[frameName.."Count"];
					if ( count > 1 and self.showAuraCount ) then
						frameCount:SetText(count);
						frameCount:Show();
					else
						frameCount:Hide();
					end

					-- Handle cooldowns
					frameCooldown = _G[frameName.."Cooldown"];
					CooldownFrame_Set(frameCooldown, expirationTime - duration, duration, duration > 0, true);

					-- set debuff type color
					if ( debuffType ) then
						color = DebuffTypeColor[debuffType];
					else
						color = DebuffTypeColor["none"];
					end
					frameBorder = _G[frameName.."Border"];
					frameBorder:SetVertexColor(color.r, color.g, color.b);

					-- set the debuff to be big if the buff is cast by the player or his pet
					numDebuffs = numDebuffs + 1;
					largeDebuffList[numDebuffs] = ShouldAuraBeLarge(caster);

					frame:ClearAllPoints();
					frame:Show();

					frameNum = frameNum + 1;
				end
			end
		else
			break;
		end
		index = index + 1;
	end

	for i = frameNum, MAX_TARGET_DEBUFFS do
		frame = _G[selfName.."Debuff"..i];
		if ( frame ) then
			frame:Hide();
		else
			break;
		end
	end

	self.auraRows = 0;

	local mirrorAurasVertically = false;
	if ( self.buffsOnTop ) then
		mirrorAurasVertically = true;
	end
	local haveTargetofTarget;
	if ( self.totFrame ) then
		haveTargetofTarget = self.totFrame:IsShown();
	end
	self.spellbarAnchor = nil;
	local maxRowWidth;
	-- update buff positions
	maxRowWidth = ( haveTargetofTarget and self.TOT_AURA_ROW_WIDTH ) or AURA_ROW_WIDTH;
	TargetFrame_UpdateAuraPositions(self, selfName.."Buff", numBuffs, numDebuffs, largeBuffList, TargetFrame_UpdateBuffAnchor, maxRowWidth, 3, mirrorAurasVertically);
	-- update debuff positions
	maxRowWidth = ( haveTargetofTarget and self.auraRows < NUM_TOT_AURA_ROWS and self.TOT_AURA_ROW_WIDTH ) or AURA_ROW_WIDTH;
	TargetFrame_UpdateAuraPositions(self, selfName.."Debuff", numDebuffs, numBuffs, largeDebuffList, TargetFrame_UpdateDebuffAnchor, maxRowWidth, 3, mirrorAurasVertically);
	-- update the spell bar position
	if ( self.spellbar ) then
		Target_Spellbar_AdjustPosition(self.spellbar);
	end
end

--
--		Hide debuffs on mobs cast by players other than me and aren't flagged to show to entire party on nameplates.
--
function TargetFrame_ShouldShowDebuffs(unit, caster, nameplateShowAll, casterIsAPlayer)
	if (GetCVarBool("noBuffDebuffFilterOnTarget")) then
		return true;
	end

	if (nameplateShowAll) then
		return true;
	end

	if (caster and (UnitIsUnit("player", caster) or UnitIsOwnerOrControllerOfUnit("player", caster))) then
		return true;
	end

	if (UnitIsUnit("player", unit)) then
		return true;
	end

	local targetIsFriendly = not UnitCanAttack("player", unit);
	local targetIsAPlayer =  UnitIsPlayer(unit);
	local targetIsAPlayerPet = UnitIsOtherPlayersPet(unit);

	if (not targetIsAPlayer and not targetIsAPlayerPet and not targetIsFriendly and casterIsAPlayer) then
        return false;
    end

    return true;
end

function TargetFrame_UpdateAuraPositions(self, auraName, numAuras, numOppositeAuras, largeAuraList, updateFunc, maxRowWidth, offsetX, mirrorAurasVertically)
	-- a lot of this complexity is in place to allow the auras to wrap around the target of target frame if it's shown

	-- Position auras
	local size;
	local offsetY = AURA_OFFSET_Y;
	-- current width of a row, increases as auras are added and resets when a new aura's width exceeds the max row width
	local rowWidth = 0;
	local firstBuffOnRow = 1;
	for i=1, numAuras do
		-- update size and offset info based on large aura status
		if ( largeAuraList[i] ) then
			size = LARGE_AURA_SIZE;
			offsetY = AURA_OFFSET_Y + AURA_OFFSET_Y;
		else
			size = SMALL_AURA_SIZE;
		end

		-- anchor the current aura
		if ( i == 1 ) then
			rowWidth = size;
			self.auraRows = self.auraRows + 1;
		else
			rowWidth = rowWidth + size + offsetX;
		end
		if ( rowWidth > maxRowWidth ) then
			-- this aura would cause the current row to exceed the max row width, so make this aura
			-- the start of a new row instead
			updateFunc(self, auraName, i, numOppositeAuras, firstBuffOnRow, size, offsetX, offsetY, mirrorAurasVertically);

			rowWidth = size;
			self.auraRows = self.auraRows + 1;
			firstBuffOnRow = i;
			offsetY = AURA_OFFSET_Y;

			if ( self.auraRows > NUM_TOT_AURA_ROWS ) then
				-- if we exceed the number of tot rows, then reset the max row width
				-- note: don't have to check if we have tot because AURA_ROW_WIDTH is the default anyway
				maxRowWidth = AURA_ROW_WIDTH;
			end
		else
			updateFunc(self, auraName, i, numOppositeAuras, i - 1, size, offsetX, offsetY, mirrorAurasVertically);
		end
	end
end

function TargetFrame_UpdateBuffAnchor(self, buffName, index, numDebuffs, anchorIndex, size, offsetX, offsetY, mirrorVertically)
	--For mirroring vertically
	local point, relativePoint;
	local startY, auraOffsetY;
	if ( mirrorVertically ) then
		point = "BOTTOM";
		relativePoint = "TOP";
		startY = -15;
		if ( self.threatNumericIndicator:IsShown() ) then
			startY = startY + self.threatNumericIndicator:GetHeight();
		end
		offsetY = - offsetY;
		auraOffsetY = -AURA_OFFSET_Y;
	else
		point = "TOP";
		relativePoint="BOTTOM";
		startY = AURA_START_Y;
		auraOffsetY = AURA_OFFSET_Y;
	end

	local buff = _G[buffName..index];
	if ( index == 1 ) then
		if ( UnitIsFriend("player", self.unit) or numDebuffs == 0 ) then
			-- unit is friendly or there are no debuffs...buffs start on top
			buff:SetPoint(point.."LEFT", self, relativePoint.."LEFT", AURA_START_X, startY);
		else
			-- unit is not friendly and we have debuffs...buffs start on bottom
			buff:SetPoint(point.."LEFT", self.debuffs, relativePoint.."LEFT", 0, -offsetY);
		end
		self.buffs:SetPoint(point.."LEFT", buff, point.."LEFT", 0, 0);
		self.buffs:SetPoint(relativePoint.."LEFT", buff, relativePoint.."LEFT", 0, -auraOffsetY);
		self.spellbarAnchor = buff;
	elseif ( anchorIndex ~= (index-1) ) then
		-- anchor index is not the previous index...must be a new row
		buff:SetPoint(point.."LEFT", _G[buffName..anchorIndex], relativePoint.."LEFT", 0, -offsetY);
		self.buffs:SetPoint(relativePoint.."LEFT", buff, relativePoint.."LEFT", 0, -auraOffsetY);
		self.spellbarAnchor = buff;
	else
		-- anchor index is the previous index
		buff:SetPoint(point.."LEFT", _G[buffName..anchorIndex], point.."RIGHT", offsetX, 0);
	end

	-- Resize
	buff:SetWidth(size);
	buff:SetHeight(size);
end

function TargetFrame_UpdateDebuffAnchor(self, debuffName, index, numBuffs, anchorIndex, size, offsetX, offsetY, mirrorVertically)
	local buff = _G[debuffName..index];
	local isFriend = UnitIsFriend("player", self.unit);

	--For mirroring vertically
	local point, relativePoint;
	local startY, auraOffsetY;
	if ( mirrorVertically ) then
		point = "BOTTOM";
		relativePoint = "TOP";
		startY = -15;
		if ( self.threatNumericIndicator:IsShown() ) then
			startY = startY + self.threatNumericIndicator:GetHeight();
		end
		offsetY = - offsetY;
		auraOffsetY = -AURA_OFFSET_Y;
	else
		point = "TOP";
		relativePoint="BOTTOM";
		startY = AURA_START_Y;
		auraOffsetY = AURA_OFFSET_Y;
	end

	if ( index == 1 ) then
		if ( isFriend and numBuffs > 0 ) then
			-- unit is friendly and there are buffs...debuffs start on bottom
			buff:SetPoint(point.."LEFT", self.buffs, relativePoint.."LEFT", 0, -offsetY);
		else
			-- unit is not friendly or there are no buffs...debuffs start on top
			buff:SetPoint(point.."LEFT", self, relativePoint.."LEFT", AURA_START_X, startY);
		end
		self.debuffs:SetPoint(point.."LEFT", buff, point.."LEFT", 0, 0);
		self.debuffs:SetPoint(relativePoint.."LEFT", buff, relativePoint.."LEFT", 0, -auraOffsetY);
		if ( ( isFriend ) or ( not isFriend and numBuffs == 0) ) then
			self.spellbarAnchor = buff;
		end
	elseif ( anchorIndex ~= (index-1) ) then
		-- anchor index is not the previous index...must be a new row
		buff:SetPoint(point.."LEFT", _G[debuffName..anchorIndex], relativePoint.."LEFT", 0, -offsetY);
		self.debuffs:SetPoint(relativePoint.."LEFT", buff, relativePoint.."LEFT", 0, -auraOffsetY);
		if ( ( isFriend ) or ( not isFriend and numBuffs == 0) ) then
			self.spellbarAnchor = buff;
		end
	else
		-- anchor index is the previous index
		buff:SetPoint(point.."LEFT", _G[debuffName..(index-1)], point.."RIGHT", offsetX, 0);
	end

	-- Resize
	buff:SetWidth(size);
	buff:SetHeight(size);
	local debuffFrame =_G[debuffName..index.."Border"];
	debuffFrame:SetWidth(size+2);
	debuffFrame:SetHeight(size+2);
end

function TargetFrame_HealthUpdate (self, elapsed, unit)
	if ( UnitIsPlayer(unit) ) then
		if ( (self.unitHPPercent > 0) and (self.unitHPPercent <= 0.2) ) then
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
				alpha = (127  + (counter * 256)) / 255;
			else
				alpha = (255 - (counter * 256)) / 255;
			end
			if ( self.portrait ) then
				self.portrait:SetAlpha(alpha);
			end
		end
	end
end

function TargetHealthCheck (self)
	if ( UnitIsPlayer(self.unit) ) then
		local unitHPMin, unitHPMax, unitCurrHP;
		local parent = self:GetParent();
		unitHPMin, unitHPMax = self:GetMinMaxValues();
		unitCurrHP = self:GetValue();
		parent.unitHPPercent = unitCurrHP / unitHPMax;
		if ( parent.portrait ) then
			if ( UnitIsDead(self.unit) ) then
				parent.portrait:SetVertexColor(0.35, 0.35, 0.35, 1.0);
			elseif ( UnitIsGhost(self.unit) ) then
				parent.portrait:SetVertexColor(0.2, 0.2, 0.75, 1.0);
			elseif ( (parent.unitHPPercent > 0) and (parent.unitHPPercent <= 0.2) ) then
				parent.portrait:SetVertexColor(1.0, 0.0, 0.0);
			else
				parent.portrait:SetVertexColor(1.0, 1.0, 1.0, 1.0);
			end
		end
	end
end

function TargetFrame_OpenMenu (self)
	local which;
	local name;
	if ( UnitIsUnit("target", "player") ) then
		which = "SELF";
	elseif ( UnitIsUnit("target", "vehicle") ) then
		-- NOTE: vehicle check must come before pet check for accuracy's sake because
		-- a vehicle may also be considered your pet
		which = "VEHICLE";
	elseif ( UnitIsUnit("target", "pet") ) then
		which = "PET";
	elseif ( UnitIsOtherPlayersPet("target") ) then
		which = "OTHERPET";
	elseif ( UnitIsPlayer("target") ) then
		if ( UnitInRaid("target") ) then
			which = "RAID_PLAYER";
		elseif ( UnitInParty("target") ) then
			which = "PARTY";
		elseif ( UnitCanCooperate("player", "target") ) then
			which = "PLAYER";
		else
			which = "ENEMY_PLAYER"
		end
	else
		which = "TARGET";
		name = RAID_TARGET_ICON;
	end
	if ( which ) then
		local contextData = {
			fromTargetFrame = true;
			unit = "target",
			name = name,
		};
		UnitPopup_OpenMenu(which, contextData);
	end
end

-- Raid target icon function
RAID_TARGET_ICON_DIMENSION = 64;
RAID_TARGET_TEXTURE_DIMENSION = 256;
RAID_TARGET_TEXTURE_COLUMNS = 4;
RAID_TARGET_TEXTURE_ROWS = 4;
function TargetFrame_UpdateRaidTargetIcon (self)
	local index = GetRaidTargetIndex(self.unit);
	if ( index ) then
		SetRaidTargetIconTexture(self.raidTargetIcon, index);
		self.raidTargetIcon:Show();
	else
		self.raidTargetIcon:Hide();
	end
end

function SetRaidTargetIconTexture (texture, raidTargetIconIndex)
	raidTargetIconIndex = raidTargetIconIndex - 1;
	local left, right, top, bottom;
	local coordIncrement = RAID_TARGET_ICON_DIMENSION / RAID_TARGET_TEXTURE_DIMENSION;
	left = mod(raidTargetIconIndex , RAID_TARGET_TEXTURE_COLUMNS) * coordIncrement;
	right = left + coordIncrement;
	top = floor(raidTargetIconIndex / RAID_TARGET_TEXTURE_ROWS) * coordIncrement;
	bottom = top + coordIncrement;
	texture:SetTexCoord(left, right, top, bottom);
end

function SetRaidTargetIcon (unit, index)
	if ( GetRaidTargetIndex(unit) and GetRaidTargetIndex(unit) == index ) then
		SetRaidTarget(unit, 0);
	else
		SetRaidTarget(unit, index);
	end
end

function TargetFrame_CreateTargetofTarget(self, unit)
	local thisName = self:GetName().."ToT";
	local frame = CreateFrame("BUTTON", thisName, self, "TargetofTargetFrameTemplate");
	self.totFrame = frame;
	UnitFrame_Initialize(frame, unit, _G[thisName.."TextureFrameName"], _G[thisName.."Portrait"],
						 _G[thisName.."HealthBar"], _G[thisName.."TextureFrameHealthBarText"],
						 _G[thisName.."ManaBar"], _G[thisName.."TextureFrameManaBarText"]);
	SetTextStatusBarTextZeroText(frame.healthbar, DEAD);
	frame.deadText = _G[thisName.."TextureFrameDeadText"];
	frame.unconsciousText = _G[thisName.."TextureFrameUnconsciousText"];
	SecureUnitButton_OnLoad(frame, unit);
end

function TargetofTarget_OnHide(self)
	TargetFrame_UpdateAuras(self:GetParent());
end

function TargetofTarget_Update(self, elapsed)
	local show;
	local parent = self:GetParent();
	if ( CVarCallbackRegistry:GetCVarValueBool("showTargetOfTarget") and UnitExists(parent.unit) and UnitExists(self.unit) and ( not UnitIsUnit(PlayerFrame.unit, parent.unit) ) and ( UnitHealth(parent.unit) > 0 ) ) then
		if ( not self:IsShown() ) then
			self:Show();
			if ( parent.spellbar ) then
				parent.haveToT = true;
				Target_Spellbar_AdjustPosition(parent.spellbar);
			end
		end
		UnitFrame_Update(self);
		TargetofTarget_CheckDead(self);
		TargetofTargetHealthCheck(self);
	else
		if ( self:IsShown() ) then
			self:Hide();
			if ( parent.spellbar ) then
				parent.haveToT = nil;
				Target_Spellbar_AdjustPosition(parent.spellbar);
			end
		end
	end
end

function TargetofTarget_UpdateDebuffs(self)
	local parent = self:GetParent();
	if ( CVarCallbackRegistry:GetCVarValueBool("showTargetOfTarget") and UnitExists(parent.unit) and UnitExists(self.unit) and ( not UnitIsUnit(PlayerFrame.unit, parent.unit) ) and ( UnitHealth(parent.unit) > 0 ) ) then
		RefreshDebuffs(self, self.unit, nil, nil, true);
	end
end

function TargetofTarget_CheckDead(self)
	if ( (UnitHealth(self.unit) <= 0) and UnitIsConnected(self.unit) ) then
		self.background:SetAlpha(0.9);
		if ( UnitIsUnconscious(self.unit) ) then
			self.unconsciousText:Show();
			self.deadText:Hide();
		else
			self.unconsciousText:Hide();
			self.deadText:Show();
		end
	else
		self.background:SetAlpha(1);
		self.deadText:Hide();
		self.unconsciousText:Hide();
	end
end

function TargetofTargetHealthCheck(self)
	if ( UnitIsPlayer(self.unit) ) then
		local unitHPMin, unitHPMax, unitCurrHP;
		unitHPMin, unitHPMax = self.healthbar:GetMinMaxValues();
		unitCurrHP = self.healthbar:GetValue();
		self.unitHPPercent = unitCurrHP / unitHPMax;
		if ( UnitIsDead(self.unit) ) then
			self.portrait:SetVertexColor(0.35, 0.35, 0.35, 1.0);
		elseif ( UnitIsGhost(self.unit) ) then
			self.portrait:SetVertexColor(0.2, 0.2, 0.75, 1.0);
		elseif ( (self.unitHPPercent > 0) and (self.unitHPPercent <= 0.2) ) then
			self.portrait:SetVertexColor(1.0, 0.0, 0.0);
		else
			self.portrait:SetVertexColor(1.0, 1.0, 1.0, 1.0);
		end
	else
		self.portrait:SetVertexColor(1.0, 1.0, 1.0, 1.0);
	end
end

function TargetFrame_CreateSpellbar(self, event, boss)
	local name = self:GetName().."SpellBar";
	local spellbar;
	if ( boss ) then
		spellbar = CreateFrame("STATUSBAR", name, self, "BossSpellBarTemplate");
	else
		spellbar = CreateFrame("STATUSBAR", name, self, "TargetSpellBarTemplate");
	end
	spellbar.boss = boss;
	spellbar:SetFrameLevel(_G[self:GetName().."TextureFrame"]:GetFrameLevel() - 1);
	self.spellbar = spellbar;
	self.auraRows = 0;
	spellbar:RegisterEvent("CVAR_UPDATE");
	spellbar:RegisterEvent("VARIABLES_LOADED");

	CastingBarFrame_SetUnit(spellbar, self.unit, false, true);
	if ( event ) then
		spellbar.updateEvent = event;
		spellbar:RegisterEvent(event);
	end

	-- check to see if the castbar should be shown
	if ( GetCVar("showTargetCastbar") == "0") then
		spellbar.showCastbar = false;
	end
end

function Target_Spellbar_OnEvent(self, event, ...)
	if( GetClassicExpansionLevel() < LE_EXPANSION_BURNING_CRUSADE ) then
		return;
	end

	local arg1 = ...

	--	Check for target specific events
	if ( (event == "VARIABLES_LOADED") or ((event == "CVAR_UPDATE") and (arg1 == "SHOW_TARGET_CASTBAR")) ) then
		if ( GetCVar("showTargetCastbar") == "0") then
			self.showCastbar = false;
		else
			self.showCastbar = true;
		end

		if ( not self.showCastbar ) then
			self:Hide();
		elseif ( self.casting or self.channeling ) then
			self:Show();
		end
		return;
	elseif ( event == self.updateEvent ) then
		-- check if the new target is casting a spell
		local nameChannel  = UnitChannelInfo(self.unit);
		local nameSpell  = UnitCastingInfo(self.unit);
		if ( nameChannel ) then
			event = "UNIT_SPELLCAST_CHANNEL_START";
			arg1 = self.unit;
		elseif ( nameSpell ) then
			event = "UNIT_SPELLCAST_START";
			arg1 = self.unit;
		else
			self.casting = nil;
			self.channeling = nil;
			self:SetMinMaxValues(0, 0);
			self:SetValue(0);
			self:Hide();
			return;
		end
		-- The position depends on the classification of the target
		Target_Spellbar_AdjustPosition(self);
	end
	CastingBarFrame_OnEvent(self, event, arg1, select(2, ...));
end

function Target_Spellbar_AdjustPosition(self)
	local parentFrame = self:GetParent();
	if ( self.boss ) then
		self:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 25, 10 );
	elseif ( parentFrame.haveToT ) then
		if ( parentFrame.buffsOnTop or parentFrame.auraRows <= 1 ) then
			self:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 25, -21 );
		else
			self:SetPoint("TOPLEFT", parentFrame.spellbarAnchor, "BOTTOMLEFT", 20, -15);
		end
	elseif ( parentFrame.haveElite ) then
		if ( parentFrame.buffsOnTop or parentFrame.auraRows <= 1 ) then
			self:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 25, -5 );
		else
			self:SetPoint("TOPLEFT", parentFrame.spellbarAnchor, "BOTTOMLEFT", 20, -15);
		end
	else
		if ( (not parentFrame.buffsOnTop) and parentFrame.auraRows > 0 ) then
			self:SetPoint("TOPLEFT", parentFrame.spellbarAnchor, "BOTTOMLEFT", 20, -15);
		else
			self:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 25, 7 );
		end
	end
end

function TargetFrame_OnDragStart(self)
	self:StartMoving();
	self:SetUserPlaced(true);
	self:SetClampedToScreen(true);
end

function TargetFrame_OnDragStop(self)
	self:StopMovingOrSizing();
end

function TargetFrame_SetLocked(locked)
	TARGET_FRAME_UNLOCKED = not locked;
	if ( locked ) then
		TargetFrame:RegisterForDrag();	--Unregister all buttons.
	else
		TargetFrame:RegisterForDrag("LeftButton");
	end
end

function TargetFrame_ResetUserPlacedPosition()
	TargetFrame:ClearAllPoints();
	TargetFrame:SetUserPlaced(false);
	TargetFrame:SetClampedToScreen(false);
	TargetFrame_SetLocked(true);
	UIParent_UpdateTopFramePositions();
end

function TargetFrame_UpdateBuffsOnTop()
	if ( TARGET_FRAME_BUFFS_ON_TOP ) then
		TargetFrame.buffsOnTop = true;
	else
		TargetFrame.buffsOnTop = false;
	end
	TargetFrame_UpdateAuras(TargetFrame);
end

-- *********************************************************************************
-- Boss Frames
-- *********************************************************************************

function BossTargetFrame_OnLoad(self, unit, event)
	self.isBossFrame = true;
	self.noTextPrefix = true;
	self.showLevel = true;
	self.showThreat = true;
	self.maxBuffs = 0;
	self.maxDebuffs = 0;
	TargetFrame_OnLoad(self, unit, BossTargetFrame_OpenMenu);
	self:RegisterEvent("UNIT_TARGETABLE_CHANGED");
	self.borderTexture:SetTexture("Interface\\TargetingFrame\\UI-UnitFrame-Boss");
	self.levelText:SetPoint("CENTER", 12, select(5, self.levelText:GetPoint(1)));
	self.raidTargetIcon:SetPoint("RIGHT", -90, 0);
	self.threatNumericIndicator:SetPoint("BOTTOM", self, "TOP", -85, -22);
	self.threatIndicator:SetTexture("Interface\\TargetingFrame\\UI-UnitFrame-Boss-Flash");
	self.threatIndicator:SetTexCoord(0.0, 0.945, 0.0, 0.73125);
	self:SetHitRectInsets(0, 95, 15, 30);
	self:SetScale(0.75);
	if ( event ) then
		self:RegisterEvent(event);
	end
end

function BossTargetFrame_OpenMenu(self)
	local contextData = 
	{
		fromTargetFrame = true;
		unit = self.unit,
		name = name,
	};
	UnitPopup_OpenMenu("BOSS", contextData);
end

-- *********************************************************************************
-- Focus Frame
-- *********************************************************************************

local FOCUS_FRAME_LOCKED = true;
local FOCUS_FRAME_MOVING = false;

FocusFrameMixin = {};

function FocusFrame_OpenMenu(self)
	local contextData = {
		fromFocusFrame = true;
		unit = "focus",
		name = SET_FOCUS,
	};
	UnitPopup_OpenMenu("FOCUS", contextData);
end

function FocusFrameMixin:IsLocked()
	return FOCUS_FRAME_LOCKED;
end

function FocusFrameMixin:SetLock(locked)
	FOCUS_FRAME_LOCKED = locked;
end

function FocusFrame_OnDragStart(self, button)
	FOCUS_FRAME_MOVING = false;
	if ( not FOCUS_FRAME_LOCKED ) then
		local cursorX, cursorY = GetCursorPosition();
		self:SetFrameStrata("DIALOG");
		self:StartMoving();
		FOCUS_FRAME_MOVING = true;
	end
end

function FocusFrame_OnDragStop(self)
	if ( not FOCUS_FRAME_LOCKED and FOCUS_FRAME_MOVING ) then
		self:StopMovingOrSizing();
		self:SetFrameStrata("BACKGROUND");
		if ( self:GetBottom() < 15 + MainMenuBar:GetHeight() ) then
			local anchorX = self:GetLeft();
			local anchorY = 60;
			if ( self.smallSize ) then
				anchorY = 90;	-- empirically determined
			end
			self:SetPoint("BOTTOMLEFT", anchorX, anchorY);
		end
		FOCUS_FRAME_MOVING = false;
	end
end

function FocusFrameMixin:SetSmallSize(smallSize, onChange)
	if ( smallSize and not FocusFrame.smallSize ) then
		local x = FocusFrame:GetLeft();
		local y = FocusFrame:GetTop();
		FocusFrame.smallSize = true;
		FocusFrame.maxBuffs = 0;
		FocusFrame.maxDebuffs = 8;
		FocusFrame:SetScale(SMALL_FOCUS_SCALE);
		FocusFrameToT:SetScale(SMALL_FOCUS_UPSCALE);
		FocusFrameToT:SetPoint("BOTTOMRIGHT", -13, -17);
		FocusFrame.TOT_AURA_ROW_WIDTH = 80;	-- not as much room for auras with scaled-up ToT frame
		FocusFrame.spellbar:SetScale(SMALL_FOCUS_UPSCALE);
		FocusFrameTextureFrameName:SetFontObject(FocusFontSmall);
		FocusFrameHealthBar.TextString:SetFontObject(TextStatusBarTextLarge);
		FocusFrameHealthBar.TextString:SetPoint("CENTER", -50, 4);
		FocusFrameTextureFrameName:SetWidth(120);
		if ( onChange ) then
			-- the frame needs to be repositioned because anchor offsets get adjusted with scale
			FocusFrame:ClearAllPoints();
			FocusFrame:SetPoint("TOPLEFT", x * SMALL_FOCUS_UPSCALE + 29, (y - GetScreenHeight()) * SMALL_FOCUS_UPSCALE - 13);
		end
		FocusFrame:UnregisterEvent("UNIT_CLASSIFICATION_CHANGED");
		FocusFrame.showClassification = true;
		FocusFrame:UnregisterEvent("PLAYER_FLAGS_CHANGED");
		FocusFrame.showLeader = nil;
		FocusFrame.showPVP = nil;
		FocusFrame.pvpIcon:Hide();
		FocusFrame.prestigePortrait:Hide();
		FocusFrame.prestigeBadge:Hide();
		FocusFrame.leaderIcon:Hide();
		FocusFrame.showAuraCount = nil;
--		TargetFrame_CheckClassification(FocusFrame, true);
		TargetFrame_Update(FocusFrame);
	elseif ( not smallSize and FocusFrame.smallSize ) then
		local x = FocusFrame:GetLeft();
		local y = FocusFrame:GetTop();
		FocusFrame.smallSize = false;
		FocusFrame.maxBuffs = nil;
		FocusFrame.maxDebuffs = nil;
		FocusFrame:SetScale(LARGE_FOCUS_SCALE);
		FocusFrameToT:SetScale(LARGE_FOCUS_SCALE);
		FocusFrameToT:SetPoint("BOTTOMRIGHT", -35, -10);
		FocusFrame.TOT_AURA_ROW_WIDTH = TOT_AURA_ROW_WIDTH;
		FocusFrame.spellbar:SetScale(LARGE_FOCUS_SCALE);
		FocusFrameTextureFrameName:SetFontObject(GameFontNormalSmall);
		FocusFrameHealthBar.TextString:SetFontObject(TextStatusBarText);
		FocusFrameHealthBar.TextString:SetPoint("CENTER", -50, 3);
		FocusFrameTextureFrameName:SetWidth(100);
		if ( onChange ) then
			-- the frame needs to be repositioned because anchor offsets get adjusted with scale
			FocusFrame:ClearAllPoints();
			FocusFrame:SetPoint("TOPLEFT", (x - 29) / SMALL_FOCUS_UPSCALE, (y + 13) / SMALL_FOCUS_UPSCALE - GetScreenHeight());
		end
		FocusFrame:RegisterEvent("UNIT_CLASSIFICATION_CHANGED");
		FocusFrame.showClassification = true;
		FocusFrame:RegisterEvent("PLAYER_FLAGS_CHANGED");
		FocusFrame.showPVP = true;
		FocusFrame.showLeader = true;
		FocusFrame.showAuraCount = true;
		TargetFrame_Update(FocusFrame);
	end
end

function FocusFrame_UpdateBuffsOnTop()
	if ( FOCUS_FRAME_BUFFS_ON_TOP ) then
		FocusFrame.buffsOnTop = true;
	else
		FocusFrame.buffsOnTop = false;
	end
	TargetFrame_UpdateAuras(FocusFrame);
end
