local STAT_COLUMN_SPACING = 5;
local STAT_COLUMNS_MAX = 7;
local SCORE_BASE_COLUMNS = 6;
local SCORE_COLUMN_WIDTH = 62;
local SCORE_BUTTON_TEXT_OFFSET = -30;
local SCORE_BUTTON_HEIGHT = 16;
local SCORE_BUTTONS_MAX = 20;

CLASS_BUTTONS = {
	["WARRIOR"]	= {0, 0.25, 0, 0.25},
	["MAGE"]		= {0.25, 0.49609375, 0, 0.25},
	["ROGUE"]		= {0.49609375, 0.7421875, 0, 0.25},
	["DRUID"]		= {0.7421875, 0.98828125, 0, 0.25},
	["HUNTER"]		= {0, 0.25, 0.25, 0.5},
	["SHAMAN"]	 	= {0.25, 0.49609375, 0.25, 0.5},
	["PRIEST"]		= {0.49609375, 0.7421875, 0.25, 0.5},
	["WARLOCK"]	= {0.7421875, 0.98828125, 0.25, 0.5},
	["PALADIN"]		= {0, 0.25, 0.5, 0.75},
	["DEATHKNIGHT"]	= {0.25, 0.49609375, 0.5, 0.75},
	["MONK"]	= {0.49609375, 0.7421875, 0.5, 0.75},
};

function WorldStateScoreFrame_OnLoad(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND");

	self:RegisterEvent("UPDATE_BATTLEFIELD_SCORE");

	-- Tab Handling code
	PanelTemplates_SetNumTabs(self, 3);

	local prevRowFrame = WorldStateScoreButton1;
	for i=2,SCORE_BUTTONS_MAX do
		local rowFrame = CreateFrame("FRAME", "WorldStateScoreButton"..i, WorldStateScoreFrame, "WorldStateScoreTemplate");
		rowFrame:SetPoint("TOPLEFT",  prevRowFrame, "BOTTOMLEFT", 0, 1);
		rowFrame:SetPoint("TOPRIGHT",  prevRowFrame, "BOTTOMRIGHT", 0, 1);
		prevRowFrame = rowFrame;
	end
	
	self.onCloseCallback = WorldStateScoreFrame_OnClose;
end

function WorldStateScoreFrame_OnEvent(self, event, ...)
	if	event == "UPDATE_BATTLEFIELD_SCORE" or event == "UPDATE_WORLD_STATES" then
		if InActiveBattlefield() and (self:IsVisible() or GetBattlefieldWinner()) then
			WorldStateScoreFrame_Resize();
			WorldStateScoreFrame_Update();
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		HideUIPanel(self);
		self.firstOpen = false;
		self.leaving = nil;
		BATTLEFIELD_SHUTDOWN_TIMER = 0;
	end
end

function WorldStateScoreFrame_OnShow(self)
	WorldStateScoreFrame_Resize();
	WorldStateScoreFrame_Update();
	WorldStateScoreFrameTab_OnClick(WorldStateScoreFrameTab1);
end

function WorldStateScoreFrame_Update()
	local isArena, isRanked = IsActiveBattlefieldArena();
	local battlefieldWinner = GetBattlefieldWinner(); 

	if ( isArena ) then
		-- Hide unused tabs
		WorldStateScoreFrameTab1:Hide();
		WorldStateScoreFrameTab2:Hide();
		WorldStateScoreFrameTab3:Hide();
	
		-- Hide unused columns
		WorldStateScoreFrameTeam:Hide();
		WorldStateScoreFrameDeaths:Hide();
		WorldStateScoreFrameHK:Hide();

		-- Reanchor some columns.
		local firstColumnOffset = 100;
		WorldStateScoreFrameDamageDone:SetPoint("LEFT", "WorldStateScoreFrameKB", "RIGHT", 0, 0);
		if ( isRanked ) then
			WorldStateScoreFrameHonorGainedText:SetText(SCORE_RATING_CHANGE);

			if ( GetCurrentArenaSeasonUsesTeams() ) then
				WorldStateScoreFrameTeam:Show();
				WorldStateScoreFrameHonorGained.sortType = "team";
				WorldStateScoreFrameKB:SetPoint("LEFT", "WorldStateScoreFrameTeam", "RIGHT", firstColumnOffset, 0);
			else
				WorldStateScoreFrameKB:SetPoint("LEFT", "WorldStateScoreFrameName", "RIGHT", firstColumnOffset, 0);
			end
		else
			WorldStateScoreFrameHonorGained:Hide();
			WorldStateScoreFrameKB:SetPoint("LEFT", "WorldStateScoreFrameName", "RIGHT", firstColumnOffset, 0);
		end
	else
		-- Show Tabs
		WorldStateScoreFrameTab1:Show();
		WorldStateScoreFrameTab2:Show();
		WorldStateScoreFrameTab3:Show();
		
		WorldStateScoreFrameTeam:Hide();
		WorldStateScoreFrameDeaths:Show();
		WorldStateScoreFrameHK:Show();
		WorldStateScoreFrameHonorGained.sortType = "cp";
		WorldStateScoreFrameHonorGainedText:SetText(SCORE_HONOR_GAINED);
		WorldStateScoreFrameHKText:SetText(SCORE_HONORABLE_KILLS);
		WorldStateScoreFrameHonorGained:Show();
		-- Reanchor some columns.
		WorldStateScoreFrameDamageDone:SetPoint("LEFT", "WorldStateScoreFrameHK", "RIGHT", 0, 0);
		WorldStateScoreFrameKB:SetPoint("LEFT", "WorldStateScoreFrameName", "RIGHT", 0, 0);
	end

	--Show the frame if its hidden and there is a victor
	if ( battlefieldWinner ) then
		-- Show the final score frame, set textures etc.
		
		if  not WorldStateScoreFrame.firstOpen then
			ShowUIPanel(WorldStateScoreFrame);
			WorldStateScoreFrame.firstOpen = true;
		end
		
		if ( isArena ) then
			WorldStateScoreFrameLeaveButton:SetText(LEAVE_ARENA);
			WorldStateScoreFrameTimerLabel:SetText(TIME_TO_PORT_ARENA);
		else
			WorldStateScoreFrameLeaveButton:SetText(LEAVE_BATTLEGROUND);				
			WorldStateScoreFrameTimerLabel:SetText(TIME_TO_PORT);
		end
		
		WorldStateScoreFrameLeaveButton:Show();
		WorldStateScoreFrameTimerLabel:Show();
		WorldStateScoreFrameTimer:Show();

		-- Show winner
		local teamName, teamRating, newTeamRating;
		if ( isArena ) then
			if ( GetCurrentArenaSeasonUsesTeams() ) then
				if ( isRanked ) then
					teamName, teamRating, newTeamRating = GetBattlefieldTeamInfo(battlefieldWinner);
					if ( teamName ) then
						WorldStateScoreWinnerFrameText:SetFormattedText(VICTORY_TEXT_ARENA_WINS, teamName);			
					else
						WorldStateScoreWinnerFrameText:SetText(VICTORY_TEXT_ARENA_DRAW);							
					end
				else
					WorldStateScoreWinnerFrameText:SetText(_G["VICTORY_TEXT_ARENA"..battlefieldWinner]);
				end
			else
				if ( battlefieldWinner == 0 or battlefieldWinner == 1) then
					WorldStateScoreWinnerFrameText:SetText(_G["VICTORY_TEXT_ARENA"..battlefieldWinner]);
				else
					WorldStateScoreWinnerFrameText:SetText(VICTORY_TEXT_ARENA_DRAW);
				end
			end
			if ( battlefieldWinner == 0 ) then
				-- Purple Team won
				WorldStateScoreWinnerFrameLeft:SetVertexColor(0.72, 0.37, 1.0);
				WorldStateScoreWinnerFrameRight:SetVertexColor(0.72, 0.37, 1.0);
				WorldStateScoreWinnerFrameText:SetVertexColor(0.72, 0.37, 1.0);	
			else		
				-- Gold Team won
				WorldStateScoreWinnerFrameLeft:SetVertexColor(0.85, 0.71, 0.26);
				WorldStateScoreWinnerFrameRight:SetVertexColor(0.85, 0.71, 0.26);
				WorldStateScoreWinnerFrameText:SetVertexColor(1, 0.82, 0);	
			end
		else
			WorldStateScoreWinnerFrameText:SetText(_G["VICTORY_TEXT"..battlefieldWinner]);
			if ( battlefieldWinner == 0 ) then
				-- Horde won
				WorldStateScoreWinnerFrameLeft:SetVertexColor(0.52, 0.075, 0.18);
				WorldStateScoreWinnerFrameRight:SetVertexColor(0.5, 0.075, 0.18);
				WorldStateScoreWinnerFrameText:SetVertexColor(1.0, 0.1, 0.1);
			else
				-- Alliance won
				WorldStateScoreWinnerFrameLeft:SetVertexColor(0.11, 0.26, 0.51);
				WorldStateScoreWinnerFrameRight:SetVertexColor(0.11, 0.26, 0.51);
				WorldStateScoreWinnerFrameText:SetVertexColor(0, 0.68, 0.94);	
			end
		end

		WorldStateScoreWinnerFrame:Show();
	else
		WorldStateScoreWinnerFrame:Hide();
		WorldStateScoreFrameLeaveButton:Hide();
		WorldStateScoreFrameTimerLabel:Hide();
		WorldStateScoreFrameTimer:Hide();
	end
	
	-- Update buttons
	local numScores = GetNumBattlefieldScores();

	local scoreButton, columnButtonIcon;
	local name, kills, killingBlows, honorableKills, deaths, honorGained, faction, rank, race, class, classToken, damageDone, healingDone, bgRating, ratingChange, preMatchMMR, mmrChange, talentSpec, honorLevel;
	local teamName, teamRating, newTeamRating, teamMMR;
	local index;
	local columnData;
	
      -- ScrollFrame update
	local hasScrollBar;
	if ( numScores > SCORE_BUTTONS_MAX ) then
		hasScrollBar = 1;
		WorldStateScoreScrollFrame:Show();
	else
		WorldStateScoreScrollFrame:Hide();
    end
	FauxScrollFrame_Update(WorldStateScoreScrollFrame, numScores, SCORE_BUTTONS_MAX, SCORE_BUTTON_HEIGHT );

	-- Setup Columns
	local text, icon, tooltip;
	local numStatColumns = GetNumBattlefieldStats();
	local columnButton, columnButtonText, columnTextButton, columnIcon;
	local honorGainedAnchorFrame = "WorldStateScoreFrameHealingDone";
	for i=1, STAT_COLUMNS_MAX do
		if ( i <= numStatColumns ) then
			text, icon, tooltip = GetBattlefieldStatInfo(i);
			columnButton = _G["WorldStateScoreColumn"..i];
			columnButtonText = _G["WorldStateScoreColumn"..i.."Text"];
			columnButtonText:SetText(text);
			columnButton.icon = icon;
			columnButton.tooltip = tooltip;
			
			columnTextButton = _G["WorldStateScoreButton1Column"..i.."Text"];

			if ( icon ~= "" ) then
				columnTextButton:SetPoint("CENTER", "WorldStateScoreColumn"..i, "CENTER", 6, -31);
			else
				columnTextButton:SetPoint("CENTER", "WorldStateScoreColumn"..i, "CENTER", -1, -31);
			end

			
			if ( i == numStatColumns ) then
				honorGainedAnchorFrame = "WorldStateScoreColumn"..i;
			end
		
			_G["WorldStateScoreColumn"..i]:Show();
		else
			_G["WorldStateScoreColumn"..i]:Hide();
		end
	end
	
	-- Anchor the bonus honor frame to the last column shown
	WorldStateScoreFrameHonorGained:SetPoint("LEFT", honorGainedAnchorFrame, "RIGHT", 0, 0);
	
	-- Last button shown is what the player count anchors to
	local lastButtonShown = "WorldStateScoreButton1";
	local teamDataFailed, coords;

	if ( isArena ) then
		for i=0, 1 do
			teamName, teamRating, newTeamRating = GetBattlefieldTeamInfo(i);
			if ( teamRating < 0 ) then
				teamDataFailed = 1;
			end
		end
		if ( isRanked and GetCurrentArenaSeasonUsesTeams() ) then
			teamName, teamRating, newTeamRating = GetBattlefieldTeamInfo(battlefieldWinner);
			if ( not teamName ) then
				teamDataFailed = 1;
			end
		end
	end

	local scrollOffset = FauxScrollFrame_GetOffset(WorldStateScoreScrollFrame);
	for i=1, SCORE_BUTTONS_MAX do
		-- Need to create an index adjusted by the scrollframe offset
		index = scrollOffset + i;
		scoreButton = _G["WorldStateScoreButton"..i];
		if ( hasScrollBar ) then
			scoreButton:SetWidth(WorldStateScoreFrame.scrollBarButtonWidth);
		else
			scoreButton:SetWidth(WorldStateScoreFrame.buttonWidth);
		end

		if ( index <= numScores ) then
			scoreButton.index = index;
			name, killingBlows, honorableKills, deaths, honorGained, faction, rank, race, class, classToken, damageDone, healingDone = GetBattlefieldScore(index);

			if GetClassicExpansionLevel() >= LE_EXPANSION_CATACLYSM then
				honorGained = honorGained / 100;
			end
		
			if ( classToken ) then
				coords = CLASS_BUTTONS[classToken];
				scoreButton.class.icon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes");
				scoreButton.class.icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4]);
				scoreButton.class:Show();
			else
				scoreButton.class:Hide();
			end

			scoreButton.name.text:SetText(name);
			if ( not race ) then
				race = "";
			end
			if ( not class ) then
				class = "";
			end
			scoreButton.name.name = name;
			scoreButton.name.tooltip = race.." "..class;
			scoreButton.class.tooltip = class;

			scoreButton.damageDone:Show();
			scoreButton.healingDone:Show();
			scoreButton.damageDone:SetText(damageDone);
			scoreButton.healingDone:SetText(healingDone);

			-- Dropdown handler for reporting a team name is on the name button. 
			scoreButton.name.teamName = nil;

			teamName, teamRating, newTeamRating, teamMMR = GetBattlefieldTeamInfo(faction);
			if ( isArena ) then
				if ( isRanked ) then
					if ( GetCurrentArenaSeasonUsesTeams() ) then
						scoreButton.team:SetText(teamName);
						scoreButton.name.teamName = teamName;
						scoreButton.team:Show();
					end

					if ( teamDataFailed == 1 ) then
						scoreButton.honorGained:SetText("-------");
					else
						local delta = newTeamRating - teamRating;
						scoreButton.honorGained:SetText(TEAM_RATING_CHANGE:format(delta, newTeamRating));
					end
					scoreButton.honorGained:Show();
				else
					scoreButton.honorGained:Hide();
					scoreButton.team:Hide();
				end
				scoreButton.honorableKills:Hide();
				scoreButton.deaths:Hide();
			else
				scoreButton.honorableKills:SetText(honorableKills);
				scoreButton.deaths:SetText(deaths);
				scoreButton.honorGained:SetText(honorGained);
				scoreButton.team:Hide();
				scoreButton.honorableKills:Show();
				scoreButton.deaths:Show();
				scoreButton.honorGained:Show();
			end

			scoreButton.killingBlows:SetText(killingBlows);
			teamDataFailed = 0;

			if ( not teamRating ) then
				teamDataFailed = 1;
			end
			
			if ( not newTeamRating ) then
				teamDataFailed = 1;
			end

			for j=1, STAT_COLUMNS_MAX do
				columnButtonText = _G["WorldStateScoreButton"..i.."Column"..j.."Text"];
				columnButtonIcon = _G["WorldStateScoreButton"..i.."Column"..j.."Icon"];
				if ( j <= numStatColumns ) then
					-- If there's an icon then move the icon left and format the text with an "x" in front
					columnData = GetBattlefieldStatData(index, j);
					if ( _G["WorldStateScoreColumn"..j].icon ~= "" ) then
						if ( columnData > 0 ) then
							columnButtonText:SetFormattedText(FLAG_COUNT_TEMPLATE, columnData);
							columnButtonIcon:SetTexture(_G["WorldStateScoreColumn"..j].icon..faction);
							columnButtonIcon:Show();
						else
							columnButtonText:SetText("");
							columnButtonIcon:Hide();
						end
						
					else
						columnButtonText:SetText(columnData);
						columnButtonIcon:Hide();
					end
					columnButtonText:Show();
				else
					columnButtonText:Hide();
					columnButtonIcon:Hide();
				end
			end
			if ( faction ) then
				if ( faction == 0 ) then
					if ( isArena ) then
						-- Purple Team 
						scoreButton.factionLeft:SetVertexColor(0.72, 0.37, 1.0);
						scoreButton.factionRight:SetVertexColor(0.72, 0.37, 1.0);
						scoreButton.name.text:SetVertexColor(0.72, 0.37, 1.0);	
					else
						-- Horde
						scoreButton.factionLeft:SetVertexColor(0.52, 0.075, 0.18);
						scoreButton.factionRight:SetVertexColor(0.5, 0.075, 0.18);
						scoreButton.name.text:SetVertexColor(1.0, 0.1, 0.1);
					end
				else
					if ( isArena ) then
						-- Gold Team 
						scoreButton.factionLeft:SetVertexColor(0.85, 0.71, 0.26);
						scoreButton.factionRight:SetVertexColor(0.85, 0.71, 0.26);
						scoreButton.name.text:SetVertexColor(1, 0.82, 0);	
					else
						-- Alliance 
						scoreButton.factionLeft:SetVertexColor(0.11, 0.26, 0.51);
						scoreButton.factionRight:SetVertexColor(0.11, 0.26, 0.51);
						scoreButton.name.text:SetVertexColor(0, 0.68, 0.94);	
					end
				end
				if ( ( not isArena ) and ( name == UnitName("player") ) ) then
					scoreButton.name.text:SetVertexColor(1.0, 0.82, 0);
				end
				scoreButton.factionLeft:Show();
				scoreButton.factionRight:Show();
			else
				scoreButton.factionLeft:Hide();
				scoreButton.factionRight:Hide();
			end
			lastButtonShown = scoreButton:GetName();
			scoreButton:Show();
		else
			scoreButton:Hide();
		end
	end

	-- Show average matchmaking rating at the bottom
	if WorldStateScoreFrame.teamAverageRating ~= nil then
		if isRatedBG or (isArena and isRegistered) then
			local _, ourAverageMMR, theirAverageMMR;
			local myFaction = GetBattlefieldArenaFaction();
			_, _, _, ourAverageMMR = GetBattlefieldTeamInfo(myFaction);
			_, _, _, theirAverageMMR = GetBattlefieldTeamInfo((myFaction+1)%2);
			WorldStateScoreFrame.teamAverageRating:Show();
			WorldStateScoreFrame.enemyTeamAverageRating:Show();
			WorldStateScoreFrame.teamAverageRating:SetFormattedText(BATTLEGROUND_YOUR_AVERAGE_RATING, ourAverageMMR);
			WorldStateScoreFrame.enemyTeamAverageRating:SetFormattedText(BATTLEGROUND_ENEMY_AVERAGE_RATING, theirAverageMMR);
		else
			WorldStateScoreFrame.teamAverageRating:Hide();
			WorldStateScoreFrame.enemyTeamAverageRating:Hide();
		end
	end
	
	-- Count number of players on each side
	local numHorde = 0;
	local numAlliance = 0;
	for i=1, numScores do
		name, killingBlows, honorableKills, deaths, honorGained, faction, rank, race, class = GetBattlefieldScore(i);	
		if ( faction ) then
			if ( faction == 0 ) then
				numHorde = numHorde + 1;
			else
				numAlliance = numAlliance + 1;
			end
		end
	end

	-- Set count text and anchor team count to last button shown
	WorldStateScorePlayerCount:Show();
	
	if ( isArena ) then
		WorldStateScorePlayerCount:Hide();
	else
		if ( numHorde > 0 and numAlliance > 0 ) then
			WorldStateScorePlayerCount:SetText(format(PLAYER_COUNT_ALLIANCE, numAlliance).." / "..format(PLAYER_COUNT_HORDE, numHorde));
		elseif ( numAlliance > 0 ) then
			WorldStateScorePlayerCount:SetFormattedText(PLAYER_COUNT_ALLIANCE, numAlliance);
		elseif ( numHorde > 0 ) then
			WorldStateScorePlayerCount:SetFormattedText(PLAYER_COUNT_HORDE, numHorde);
		else
			WorldStateScorePlayerCount:Hide();
		end
		WorldStateScorePlayerCount:SetPoint("TOPLEFT", lastButtonShown, "BOTTOMLEFT", 15, -6);
	end

	if GetBattlefieldInstanceRunTime() > 60000 then
		WorldStateScoreBattlegroundRunTime:Show();
		WorldStateScoreBattlegroundRunTime:SetText(TIME_ELAPSED.." "..SecondsToTime(GetBattlefieldInstanceRunTime()/1000, true));
	else
		WorldStateScoreBattlegroundRunTime:Hide();
	end
	WorldStateScoreBattlegroundRunTime:SetPoint("TOPRIGHT", lastButtonShown, "BOTTOMRIGHT", -20, -7);
end

function WorldStateScoreFrame_Resize()
	local isArena, isRanked = IsActiveBattlefieldArena();
	local columns;
	local rightPadding = 300;
	local width =  WorldStateScoreFrameName:GetWidth() + WorldStateScoreFrameClass:GetWidth() + rightPadding;
	if ( isArena ) then
		columns = 3;
		if ( isRanked ) then
			columns = columns + 1; -- Rating
			if ( GetCurrentArenaSeasonUsesTeams() ) then
				width = width + WorldStateScoreFrameTeam:GetWidth();
			end
		end
	else
		columns = SCORE_BASE_COLUMNS;
	end
	local numBattlefieldStats = GetNumBattlefieldStats();
	columns = columns + numBattlefieldStats
	width = width + (columns * SCORE_COLUMN_WIDTH) + ((numBattlefieldStats - 1) * STAT_COLUMN_SPACING);
	if ( WorldStateScoreScrollFrame:IsShown() ) then
		local scrollBar = 37;
		width = width + scrollBar;
	end

	local uncroppedTextureWidth = 129;
	WorldStateScoreFrame:SetWidth(width + uncroppedTextureWidth);
	WorldStateScoreFrameTopBackground:SetWidth(width);
	WorldStateScoreFrameTopBackground:SetTexCoord(0, width/256, 0, 1.0);
	WorldStateScoreFrame.scrollBarButtonWidth = width;
	WorldStateScoreFrame.buttonWidth = WorldStateScoreFrame:GetWidth() - 137;
	WorldStateScoreScrollFrame:SetWidth(width);
	 
	-- Position Column data horizontally
	for i=1, SCORE_BUTTONS_MAX do
		local scoreButton = _G["WorldStateScoreButton"..i];
		
		if ( i == 1 ) then
			scoreButton.team:SetPoint("LEFT", "WorldStateScoreFrameTeam", "LEFT", 0, SCORE_BUTTON_TEXT_OFFSET);
			scoreButton.honorableKills:SetPoint("CENTER", "WorldStateScoreFrameHK", "CENTER", 0, SCORE_BUTTON_TEXT_OFFSET);
			scoreButton.killingBlows:SetPoint("CENTER", "WorldStateScoreFrameKB", "CENTER", 0, SCORE_BUTTON_TEXT_OFFSET);
			scoreButton.deaths:SetPoint("CENTER", "WorldStateScoreFrameDeaths", "CENTER", 0, SCORE_BUTTON_TEXT_OFFSET);
			scoreButton.honorGained:SetPoint("CENTER", "WorldStateScoreFrameHonorGained", "CENTER", 0, SCORE_BUTTON_TEXT_OFFSET);
			scoreButton.damageDone:SetPoint("CENTER", "WorldStateScoreFrameDamageDone", "CENTER", 0, SCORE_BUTTON_TEXT_OFFSET);
			scoreButton.healingDone:SetPoint("CENTER", "WorldStateScoreFrameHealingDone", "CENTER", 0, SCORE_BUTTON_TEXT_OFFSET);
			for j=1, STAT_COLUMNS_MAX do
				_G["WorldStateScoreButton"..i.."Column"..j.."Text"]:SetPoint("CENTER", _G["WorldStateScoreColumn"..j], "CENTER", 0, SCORE_BUTTON_TEXT_OFFSET);
			end
		else
			local offset = SCORE_BUTTON_HEIGHT - 1;
			scoreButton.team:SetPoint("LEFT", "WorldStateScoreButton"..(i-1).."Team", "LEFT", 0, -offset);
			scoreButton.honorableKills:SetPoint("CENTER", "WorldStateScoreButton"..(i-1).."HonorableKills", "CENTER", 0, -offset);
			scoreButton.killingBlows:SetPoint("CENTER", "WorldStateScoreButton"..(i-1).."KillingBlows", "CENTER", 0, -offset);
			scoreButton.deaths:SetPoint("CENTER", "WorldStateScoreButton"..(i-1).."Deaths", "CENTER", 0, -offset);
			scoreButton.honorGained:SetPoint("CENTER", "WorldStateScoreButton"..(i-1).."HonorGained", "CENTER", 0, -offset);
			scoreButton.damageDone:SetPoint("CENTER", "WorldStateScoreButton"..(i-1).."DamageDone", "CENTER", 0, -offset);
			scoreButton.healingDone:SetPoint("CENTER", "WorldStateScoreButton"..(i-1).."HealingDone", "CENTER", 0, -offset);
			for j=1, STAT_COLUMNS_MAX do
				_G["WorldStateScoreButton"..i.."Column"..j.."Text"]:SetPoint("CENTER", "WorldStateScoreButton"..(i-1).."Column"..j.."Text", "CENTER", 0, -offset);
			end
		end
	end
	return width;
end

function WorldStateScoreFrame_OnClose(self)
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE);
	HideParentPanel(self);
end

function WorldStateScoreFrame_OnHide(self)
end

function WorldStateScoreFrame_OnVerticalScroll(self, offset)
	FauxScrollFrame_OnVerticalScroll(self, offset, SCORE_BUTTON_HEIGHT, WorldStateScoreFrame_Update);
end

function WorldStateScoreFrameTab_OnClick(tab)
	local faction = tab:GetID();
	PanelTemplates_SetTab(WorldStateScoreFrame, faction);
	if ( faction == 2 ) then
		faction = 1;
	elseif ( faction == 3 ) then
		faction = 0;
	else
		faction = nil;
	end
	WorldStateScoreFrameLabel:SetFormattedText(STAT_TEMPLATE, tab:GetText());
	SetBattlefieldScoreFaction(faction);
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
end

function ToggleWorldStateScoreFrame()
	if ( WorldStateScoreFrame:IsShown() ) then
		HideUIPanel(WorldStateScoreFrame);
	else
		--Make sure we're in an active BG
		local activeStatus = false;
		for i=1, GetMaxBattlefieldID() do
			local status = GetBattlefieldStatus(i);
			if ( status == "active" ) then
				activeStatus = true;
				break;
			end
		end

		if ( activeStatus and (not IsActiveBattlefieldArena() or GetBattlefieldWinner()) ) then
			ShowUIPanel(WorldStateScoreFrame);
		end
	end
end

function ScorePlayer_OnMouseUp(self, mouseButton)
	if ( mouseButton == "RightButton" ) then
		if ( not UnitIsUnit(self.name,"player") ) then
			local contextData = 
			{
				name = self.name,
				battlefieldScoreIndex = self:GetParent().index,
				teamName = self.teamName,
			};

			UnitPopup_OpenMenu("WORLD_STATE_SCORE", contextData);
		end
	elseif ( mouseButton == "LeftButton" and IsModifiedClick("CHATLINK") and ChatEdit_GetActiveWindow() ) then
		ChatEdit_InsertLink(self.text:GetText());
	end
end

--
-- Challenge Mode - only 1 timer for now, needs some work for multiple timers
--

function WorldStateChallengeMode_OnLoad(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("WORLD_STATE_TIMER_START");
	self:RegisterEvent("WORLD_STATE_TIMER_STOP");
end

function WorldStateChallengeMode_OnEvent(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		WorldStateChallengeMode_CheckTimers(GetWorldElapsedTimers());
	elseif event == "WORLD_STATE_TIMER_START" then
		local timerID = ...;
		WorldStateChallengeMode_CheckTimers(timerID);
	elseif event == "WORLD_STATE_TIMER_STOP" then
		local timerID = ...;
		WorldStateChallengeMode_HideTimer(timerID);
	end

end

-- WatchFrame handler function
function WorldStateChallengeMode_DisplayTimers(lineFrame, nextAnchor, maxHeight, frameWidth)
	local self = WorldStateChallengeModeFrame;
	if ( self.timerID ) then
		self:SetParent(lineFrame);
		if (nextAnchor) then
			self:SetPoint("TOPLEFT", nextAnchor, "BOTTOMLEFT", 0, -WATCHFRAME_TYPE_OFFSET);
		else
			self:SetPoint("TOPLEFT", lineFrame, "TOPLEFT", 0, -WATCHFRAME_INITIAL_OFFSET)
		end
		local _, elapsedTime = GetWorldElapsedTime(self.timerID);
		WorldStateChallengeModeTimer.baseTime = elapsedTime;
		WorldStateChallengeModeTimer.timeSinceBase = 0;
		WorldStateChallengeModeTimer.frame = self;
		self:Show();
		return self, 198, 0, 1;
	else
		-- handler should have been removed before this...
		self:Hide();
		return nextAnchor, 0, 0, 0;
	end
end

function WorldStateChallengeMode_CheckTimers(...)
	for i = 1, select("#", ...) do
		local timerID = select(i, ...);
		local _, elapsedTime, type = GetWorldElapsedTime(timerID);
		if ( type == LE_WORLD_ELAPSED_TIMER_TYPE_CHALLENGE_MODE) then
			local _, _, _, _, _, _, _, mapID = GetInstanceInfo();
			if ( mapID ) then
				WorldStateChallengeMode_ShowTimer(timerID, elapsedTime, C_ChallengeMode.GetChallengeModeMapTimes(mapID));
				return;
			end
		end	
	end
	WorldStateChallengeMode_HideTimer();
end

function WorldStateChallengeMode_ShowTimer(timerID, elapsedTime, times)
	local self = WorldStateChallengeModeFrame;
	if not ( self.medalTimes ) then
		self.medalTimes = { };
	end
	for i = 1, #times do
		self.medalTimes[i] = times[i]
	end
	-- not currently being displayed, set up handler
	if ( not self.timerID ) then
		WatchFrame_AddObjectiveHandler(WorldStateChallengeMode_DisplayTimers, 1);
		if ( WatchFrame_RemoveObjectiveHandler(WatchFrame_DisplayTrackedQuests) ) then
			self.hidWatchedQuests = true;
		end
	end
	self.timerID = timerID;
	WorldStateChallengeModeFrame_UpdateMedal(self, elapsedTime);
	WorldStateChallengeModeFrame_UpdateValues(self, elapsedTime);
	WatchFrame_ClearDisplay();
	WatchFrame_Expand(WatchFrame);	-- will automatically do a watchframe update
	WorldStateChallengeModeTimer:Show();
end

function WorldStateChallengeMode_HideTimer(timerID)
	local self = WorldStateChallengeModeFrame;
	if ( not timerID or self.timerID == timerID ) then
		self.timerID = nil;
		if ( self.hidWatchedQuests ) then
			WatchFrame_AddObjectiveHandler(WatchFrame_DisplayTrackedQuests);
		end
		self:Hide();
		WorldStateChallengeModeTimer:Hide();
		self.lastMedalShown = nil;
		WatchFrame_RemoveObjectiveHandler(WorldStateChallengeMode_DisplayTimers);
		WatchFrame_ClearDisplay();
		WatchFrame_Update(WatchFrame);
	end
end

function WorldStateChallengeModeFrame_UpdateMedal(self, elapsedTime)
	-- find best medal for current time
	local prevMedalTime = 0;
	for i = #self.medalTimes, 1, -1 do
		local currentMedalTime = self.medalTimes[i];
		if ( elapsedTime < currentMedalTime ) then
			self.statusBar:SetMinMaxValues(0, currentMedalTime - prevMedalTime);
			self.statusBar.medalTime = currentMedalTime;
			if ( CHALLENGE_MEDAL_TEXTURES[i] ) then
				self.medalIcon:SetTexture(CHALLENGE_MEDAL_TEXTURES[i]);
				self.medalIcon:Show();
				self.GlowFrame.MedalIcon:SetTexture(CHALLENGE_MEDAL_TEXTURES[i]);
				self.GlowFrame.MedalGlowAnim:Play();
			end
			self.noMedal:Hide();
			-- play sound if medal changed
			if ( self.lastMedalShown and self.lastMedalShown ~= i ) then
				if ( self.lastMedalShown == CHALLENGE_MEDAL_GOLD ) then
					PlaySound(SOUNDKIT.UI_CHALLENGES_MEDALEXPIRE_GOLDTOSILVER);
				elseif ( self.lastMedalShown == CHALLENGE_MEDAL_SILVER ) then
					PlaySound(SOUNDKIT.UI_CHALLENGES_MEDALEXPIRE_SILVERTOBRONZE);
				else
					PlaySound(SOUNDKIT.UI_CHALLENGES_MEDALEXPIRE);
				end
			end
			self.lastMedalShown = i;
			return;
		else
			prevMedalTime = currentMedalTime;
		end
	end
	-- no medal
	self.statusBar.timeLeft:SetText(CHALLENGES_TIMER_NO_MEDAL);
	self.statusBar:SetValue(0);
	self.statusBar.medalTime = nil;
	self.noMedal:Show();
	self.medalIcon:Hide();
	-- play sound if medal changed
	if ( self.lastMedalShown and self.lastMedalShown ~= 0 ) then
		PlaySound(SOUNDKIT.UI_CHALLENGES_MEDALEXPIRE);
	end
	self.lastMedalShown = 0;
end

function WorldStateChallengeModeFrame_UpdateValues(self, elapsedTime)
	local statusBar = self.statusBar;
	if ( statusBar.medalTime ) then
		local timeLeft = statusBar.medalTime - elapsedTime;
		local anim = self.GlowFrame.MedalPulseAnim;
		if (timeLeft <= 5) then
			if (anim:IsPlaying()) then 
				anim.timeLeft = timeLeft;
			else
				self.GlowFrame.MedalPulseAnim:Play();
			end
		end
		if (timeLeft == 10) then
			if (not self.playedSound) then
				PlaySound(SOUNDKIT.UI_CHALLENGES_WARNING);
				self.playedSound = true;
			end
		else
			self.playedSound = false;
		end
		if ( timeLeft < 0 ) then
			WorldStateChallengeModeFrame_UpdateMedal(self, elapsedTime);
		else
			statusBar:SetValue(statusBar.medalTime - elapsedTime);
			statusBar.timeLeft:SetText(GetTimeStringFromSeconds(statusBar.medalTime - elapsedTime));
		end
	end
end

function WorldStateChallengeModeAnim_OnFinished(self)
	if (self.timeLeft and self.timeLeft > 0 and self.timeLeft < 5) then
		self:Play();
	else
		self.timeLeft = nil;
	end
end

local floor = floor; --optimization so we don't do a global lookup on update
function WorldStateChallengeModeTimer_OnUpdate(self, elapsed)
	self.timeSinceBase = self.timeSinceBase + elapsed;
	WorldStateChallengeModeFrame_UpdateValues(self.frame, floor(self.baseTime + self.timeSinceBase));
end

--
-- Proving Grounds
--

-- WatchFrame handler function
function WorldStateProvingGrounds_DisplayTimers(lineFrame, nextAnchor, maxHeight, frameWidth)
	local self = WorldStateProvingGroundsFrame;
	if ( self.timerID ) then
		self:SetParent(lineFrame);
		if (nextAnchor) then
			self:SetPoint("TOPLEFT", nextAnchor, "BOTTOMLEFT", 0, -WATCHFRAME_TYPE_OFFSET);
		else
			self:SetPoint("TOPLEFT", lineFrame, "TOPLEFT", 0, -WATCHFRAME_INITIAL_OFFSET)
		end
		local _, elapsedTime = GetWorldElapsedTime(self.timerID);
		WorldStateProvingGroundsTimer.baseTime = elapsedTime;
		WorldStateProvingGroundsTimer.timeSinceBase = 0;
		WorldStateProvingGroundsTimer.frame = self;
		self:Show();
		WatchFrameScenario_UpdateScenario();
		return self, 198, 0, 1;
	else
		-- handler should have been removed before this...
		self:Hide();
		return nextAnchor, 0, 0, 0;
	end
end

function WorldStateProvingGrounds_CheckTimers(...)
	for i = 1, select("#", ...) do
		local timerID = select(i, ...);
		local _, elapsedTime, type = GetWorldElapsedTime(timerID);
		if ( type == LE_WORLD_ELAPSED_TIMER_TYPE_PROVING_GROUND) then
			local diffID, currWave, maxWave, duration = C_Scenario.GetProvingGroundsInfo()
			if (duration > 0) then
				WorldStateProvingGrounds_ShowTimer(timerID, elapsedTime, duration, diffID, currWave, maxWave);
				return;
			end
		end	
	end
	WorldStateProvingGrounds_HideTimer();
end

local PROVING_GROUNDS_ENDLESS_INDEX = 4;
function WorldStateProvingGrounds_ShowTimer(timerID, elapsedTime, duration, medalIndex, currWave, maxWave)
	local self = WorldStateProvingGroundsFrame;
	local statusBar = self.statusBar;
	
	-- not currently being displayed, set up handler
	if ( not self.timerID ) then
		WatchFrame_AddObjectiveHandler(WorldStateProvingGrounds_DisplayTimers, 1);
		if ( WatchFrame_RemoveObjectiveHandler(WatchFrame_DisplayTrackedQuests) ) then
			self.hidWatchedQuests = true;
		end
	end
	
	self.timerID = timerID;
	statusBar.duration = duration;
	statusBar:SetMinMaxValues(0, duration);
	if ( CHALLENGE_MEDAL_TEXTURES[medalIndex] ) then
		self.MedalIcon:SetTexture(CHALLENGE_MEDAL_TEXTURES[medalIndex]);
		self.MedalIcon:Show();
	end
	
	if (medalIndex < PROVING_GROUNDS_ENDLESS_INDEX) then
		self.ScoreLabel:Hide();
		self.Score:Hide();
		self.WaveLabel:SetPoint("TOPLEFT", self.MedalIcon, "TOPRIGHT", 1, -4);
		self.Wave:SetFormattedText(GENERIC_FRACTION_STRING, currWave, maxWave);
		statusBar:SetPoint("CENTER", self, "CENTER", 22, -8);
	else
		self.ScoreLabel:Show();
		self.Score:Show();
		self.WaveLabel:SetPoint("TOPLEFT", self.MedalIcon, "TOPRIGHT", 1, 4);
		self.Wave:SetText(currWave);
		statusBar:SetPoint("CENTER", self, "CENTER", 22, -17);
	end
	
	self:RegisterEvent("PROVING_GROUNDS_SCORE_UPDATE");
	WorldStateProvingGroundsFrame_UpdateValues(self, elapsedTime);
	self.CountdownAnim.timeLeft = nil;
	WatchFrame_ClearDisplay();
	WatchFrame_Expand(WatchFrame);	-- will automatically do a watchframe update
	WorldStateProvingGroundsTimer:Show();
end

function WorldStateProvingGrounds_HideTimer(timerID)
	local self = WorldStateProvingGroundsFrame;
	if ( not timerID or self.timerID == timerID ) then
		self.timerID = nil;
		if ( self.hidWatchedQuests ) then
			WatchFrame_AddObjectiveHandler(WatchFrame_DisplayTrackedQuests);
		end
		self:UnregisterEvent("PROVING_GROUNDS_SCORE_UPDATE");
		self:Hide();
		WorldStateProvingGroundsTimer:Hide();
		WatchFrame_RemoveObjectiveHandler(WorldStateProvingGrounds_DisplayTimers);
		WatchFrame_ClearDisplay();
		WatchFrame_Update(WatchFrame);
	end
end

function WorldStateProvingGroundsFrame_UpdateValues(self, elapsedTime)
	WatchFrameHeader:Show()
	local statusBar = self.statusBar;
	if ( elapsedTime < statusBar.duration ) then
		statusBar:SetValue(statusBar.duration - elapsedTime);
		statusBar.timeLeft:SetText(GetTimeStringFromSeconds(statusBar.duration - elapsedTime));
		
		local timeLeft = statusBar.duration - elapsedTime;
		local anim = self.CountdownAnim;
		if (timeLeft <= 5) then
			if (anim:IsPlaying()) then 
				anim.timeLeft = timeLeft;
			else
				anim:Play();
			end
		elseif (anim.timeLeft ~= nil) then
			-- the time left never reaches 0 if there's another wave, but the animation always needs to get to 0
			anim.timeLeft = 0; 
		end
	end
end

function WorldStateProvingGrounds_OnEvent(self, event, ...)
	if (event == "PROVING_GROUNDS_SCORE_UPDATE") then
		local score = ...
		self.Score:SetText(score);
	end
end

function WorldStateProvingGroundsTimer_OnUpdate(self, elapsed)
	self.timeSinceBase = self.timeSinceBase + elapsed;
	WorldStateProvingGroundsFrame_UpdateValues(self.frame, floor(self.baseTime + self.timeSinceBase));
end

function WorldStateProvingGroundsAnim_OnFinished(self)
	if (self.timeLeft and self.timeLeft > 0 and self.timeLeft < 5) then
		self:Play();
	else
		self.timeLeft = nil;
	end
end
