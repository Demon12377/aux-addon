-- Who watches the WatchFrame...?

WATCHFRAME_COLLAPSEDWIDTH = 0;		-- set in WatchFrame_OnLoad
WATCHFRAME_EXPANDEDWIDTH = 204;
WATCHFRAME_LINEHEIGHT = 16;
WATCHFRAME_MAXLINEWIDTH = 0;		-- set in WatchFrame_SetWidth
WATCHFRAME_MULTIPLE_LINEHEIGHT = 29;
WATCHFRAME_ITEM_WIDTH = 33;

local DASH_NONE = 0;
local DASH_SHOW = 1;
local DASH_HIDE = 2;
local DASH_WIDTH;
local IS_HEADER = true;

WATCHFRAME_INITIAL_OFFSET = 0;
WATCHFRAME_TYPE_OFFSET = 10;
WATCHFRAME_QUEST_OFFSET = 10;

WATCHFRAMELINES_FONTSPACING = 0;
WATCHFRAMELINES_FONTHEIGHT = 0;

WATCHFRAME_MAXQUESTS = 10;
WATCHFRAME_MAXACHIEVEMENTS = 10;
WATCHFRAME_CRITERIA_PER_ACHIEVEMENT = 5;

WATCHFRAME_NUM_TIMERS = 0;
WATCHFRAME_NUM_ITEMS = 0;

WATCHFRAME_OBJECTIVEHANDLERS = {};
WATCHFRAME_TIMEDCRITERIA = {};
WATCHFRAME_TIMERLINES = {};
WATCHFRAME_ACHIEVEMENTLINES = {};
WATCHFRAME_QUESTLINES = {};
WATCHFRAME_LINKBUTTONS = {};
local WATCHFRAME_SETLINES = { };			-- buffer to hold lines for a quest/achievement that will be displayed only if there is room
local WATCHFRAME_SETLINES_NUMLINES;		-- the number of visual lines to be rendered for the buffered data - used just for item wrapping right now

CURRENT_MAP_QUESTS = { };
LOCAL_MAP_QUESTS = { };
VISIBLE_WATCHES  = { };

WATCHFRAME_FLAGS = { ["locked"] = 0x01, ["collapsed"] = 0x02 }

WATCHFRAME_ACHIEVEMENT_ARENA_CATEGORY = 165;

local watchFrameTestLine;
WATCHFRAME_SORT_DIFFICULTY_HIGH = 1;
WATCHFRAME_SORT_DIFFICULTY_LOW = 2;
WATCHFRAME_SORT_MANUAL = 0;
WATCHFRAME_FILTER_ACHIEVEMENTS = 1;
WATCHFRAME_FILTER_COMPLETED_QUESTS = 2;
WATCHFRAME_FILTER_REMOTE_ZONES = 4;
WATCHFRAME_FILTER_NONE = 0;
WATCHFRAME_SORT_TYPE = 0;
WATCHFRAME_FILTER_TYPE = 0;
WATCHFRAME_UPDATE_RATE = 1;

local watchButtonIndex = 1;
local function WatchFrame_GetLinkButton ()
	local button = WATCHFRAME_LINKBUTTONS[watchButtonIndex]
	if ( not button ) then
		WATCHFRAME_LINKBUTTONS[watchButtonIndex] = WatchFrame.buttonPool:Acquire();
		button = WATCHFRAME_LINKBUTTONS[watchButtonIndex];
	end

	watchButtonIndex = watchButtonIndex + 1;
	return button;
end

local function WatchFrame_ResetLinkButtons ()
	watchButtonIndex = 1;
end

local function WatchFrame_ReleaseUnusedLinkButtons ()
	local watchButton
	for i = watchButtonIndex, #WATCHFRAME_LINKBUTTONS do
		watchButton = WATCHFRAME_LINKBUTTONS[i];
		watchButton.type = nil
		watchButton.index = nil;
		WatchFrame.buttonPool:Release(watchButton);
		WATCHFRAME_LINKBUTTONS[i] = nil;
	end
end

function WatchFrameLinkButtonTemplate_ShowContextMenu(self, button)
	MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
		rootDescription:SetTag("MENU_WATCH_FRAME_LINK");

		if ( self.type == "QUEST" ) then
			local questLogIndex = GetQuestIndexForWatch(self.index);
			local questTitle = GetQuestLogTitle(questLogIndex);
			rootDescription:CreateTitle(questTitle);
			rootDescription:CreateButton(OBJECTIVES_VIEW_IN_QUESTLOG, function()
				WatchFrame_OpenQuestLog(button, self.index, true);
			end);

			rootDescription:CreateButton(OBJECTIVES_STOP_TRACKING, function()
				WatchFrame_StopTrackingQuest(button, self.index);
			end);

			if ( GetQuestLogPushable(GetQuestIndexForWatch(self.index)) and ( GetNumGroupMembers() > 0 ) ) then
				rootDescription:CreateButton(SHARE_QUEST, function()
					WatchFrame_ShareQuest(button, self.index);
				end);
			end

			if ( WatchFrame.showObjectives ) then
				rootDescription:CreateButton(OBJECTIVES_SHOW_QUEST_MAP, function()
					WatchFrame_OpenMapToQuest(button, self.index);
				end);
			end
			local numVisibleWatches = #VISIBLE_WATCHES;
			if ( numVisibleWatches > 1 ) then
				local visibleIndex = WatchFrame_GetVisibleIndex(questLogIndex);
				if ( visibleIndex > 1 ) then
					rootDescription:CreateButton(TRACKER_SORT_MANUAL_UP, function()
						WatchFrame_MoveQuest(button, questLogIndex, -1);
					end);

					rootDescription:CreateButton(TRACKER_SORT_MANUAL_TOP, function()
						WatchFrame_MoveQuest(button, questLogIndex, -100);
					end);
				end
				if ( visibleIndex < numVisibleWatches ) then
					rootDescription:CreateButton(TRACKER_SORT_MANUAL_DOWN, function()
						WatchFrame_MoveQuest(button, questLogIndex, 1);
					end);

					rootDescription:CreateButton(TRACKER_SORT_MANUAL_BOTTOM, function()
						WatchFrame_MoveQuest(button, questLogIndex, 100);
					end);
				end
			end
		elseif ( self.type == "ACHIEVEMENT" ) then

			local _, achievementName = GetAchievementInfo(self.index);
			rootDescription:CreateTitle(achievementName);

			rootDescription:CreateButton(OBJECTIVES_VIEW_ACHIEVEMENT, function()
				WatchFrame_OpenAchievementFrame(button, self.index);
			end);

			rootDescription:CreateButton(OBJECTIVES_STOP_TRACKING, function()
				WatchFrame_StopTrackingAchievement(button, self.index);
			end);
		end
	end);
end

function WatchFrameLinkButtonTemplate_OnClick (self, button, pushed)
	if ( IsModifiedClick("CHATLINK") and ChatEdit_GetActiveWindow() ) then
		if ( self.type == "QUEST" ) then
			local questIndex = GetQuestIndexForWatch(self.index);
			local questLink = GetQuestLink(GetQuestIDFromLogIndex(questIndex));
			if ( questLink ) then
				ChatEdit_InsertLink(questLink);
			end
		elseif ( self.type == "ACHIEVEMENT" ) then
			local achievementLink = GetAchievementLink(self.index);
			if ( achievementLink ) then
				ChatEdit_InsertLink(achievementLink);
			end
		end
	elseif ( button ~= "RightButton" ) then
		WatchFrameLinkButtonTemplate_OnLeftClick(self, button);
	else
		WatchFrameLinkButtonTemplate_ShowContextMenu(self, button);
	end
end

function WatchFrameLinkButtonTemplate_OnLeftClick (self, button)
	if ( self.type == "QUEST" ) then
		if ( IsModifiedClick("QUESTWATCHTOGGLE") ) then
			WatchFrame_StopTrackingQuest( button, self.index);
		else
			ExpandQuestHeader( GetQuestSortIndex( GetQuestIndexForWatch(self.index) ) );
			-- you have to call GetQuestIndexForWatch again because ExpandQuestHeader will sort the indices
			local questIndex = GetQuestIndexForWatch(self.index);
			if (self.isComplete and GetQuestLogIsAutoComplete(questIndex)) then
				ShowQuestComplete(questIndex);
				WatchFrameAutoQuest_ClearPopUpByLogIndex(questIndex);
			else
				QuestLog_OpenToQuest( questIndex );
				QuestLogControlPanel_UpdateState();
			end
		end
		return;
	elseif ( self.type == "ACHIEVEMENT" ) then
		if ( not AchievementFrame ) then
			AchievementFrame_LoadUI();
		end
		if ( IsModifiedClick("QUESTWATCHTOGGLE") ) then
			WatchFrame_StopTrackingAchievement(button, self.index);
		elseif ( not AchievementFrame:IsShown() ) then
			AchievementFrame_ToggleAchievementFrame();
			AchievementFrame_SelectAchievement(self.index);
		else
			if ( AchievementFrameAchievements.selection ~= self.index ) then
				AchievementFrame_SelectAchievement(self.index);
			else
				AchievementFrame_ToggleAchievementFrame();
			end
		end
		return;
	end
end

local achievementLineIndex = 1;
local function WatchFrame_GetAchievementLine ()
	local line = WATCHFRAME_ACHIEVEMENTLINES[achievementLineIndex];
	if ( not line ) then
		WATCHFRAME_ACHIEVEMENTLINES[achievementLineIndex] = WatchFrame.linePool:Acquire();
		line = WATCHFRAME_ACHIEVEMENTLINES[achievementLineIndex];
	end

	line:Reset();
	achievementLineIndex = achievementLineIndex + 1;
	return line;
end

local function WatchFrame_ResetAchievementLines ()
	achievementLineIndex = 1;
end

local function WatchFrame_ReleaseUnusedAchievementLines ()
	local line
	for i = achievementLineIndex, #WATCHFRAME_ACHIEVEMENTLINES do
		line = WATCHFRAME_ACHIEVEMENTLINES[i];
		WatchFrame.linePool:Release(line);
		WATCHFRAME_ACHIEVEMENTLINES[i] = nil;
	end
end

local questLineIndex = 1;
local function WatchFrame_GetQuestLine ()
	local line = WATCHFRAME_QUESTLINES[questLineIndex];
	if ( not line ) then
		WATCHFRAME_QUESTLINES[questLineIndex] = WatchFrame.linePool:Acquire();
		line = WATCHFRAME_QUESTLINES[questLineIndex];
	end

	line:Reset();
	questLineIndex = questLineIndex + 1;
	return line;
end

local function WatchFrame_ResetQuestLines ()
	questLineIndex = 1;
end

local function WatchFrame_ReleaseUnusedQuestLines ()
	local line;
	for i = questLineIndex, #WATCHFRAME_QUESTLINES do
		line = WATCHFRAME_QUESTLINES[i];
		WatchFrame.linePool:Release(line);
		WATCHFRAME_QUESTLINES[i] = nil;
	end
end

function WatchFrame_OnLoad (self)
	self:RegisterEvent("QUEST_LOG_UPDATE");
	self:RegisterEvent("TRACKED_ACHIEVEMENT_UPDATE");
	self:RegisterEvent("ITEM_PUSH");
	self:RegisterEvent("DISPLAY_SIZE_CHANGED");
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA");
	self:RegisterEvent("PLAYER_MONEY");
	self:RegisterEvent("VARIABLES_LOADED");
	self:RegisterEvent("QUEST_POI_UPDATE");
	self:RegisterEvent("QUEST_ACCEPTED");
	self:RegisterEvent("QUEST_AUTOCOMPLETE");
	self:SetScript("OnSizeChanged", WatchFrame_OnSizeChanged); -- Has to be set here instead of in XML for now due to OnSizeChanged scripts getting run before OnLoad scripts.
	self.linePool = CreateFramePool("FRAME", WatchFrameLines, "WatchFrameLineTemplate");
	self.buttonPool = CreateFramePool("BUTTON", WatchFrameLines, "WatchFrameLinkButtonTemplate");

	local onCreateFunc = nil;
	local useHighlightManager = false;
	QuestPOI_Initialize(WatchFrameLines, onCreateFunc, useHighlightManager);

	watchFrameTestLine = self.linePool:Acquire();
	local titleWidth = WatchFrameTitle:GetWidth();
	WATCHFRAME_COLLAPSEDWIDTH = WatchFrameTitle:GetWidth() + 70;
	local _, fontHeight = watchFrameTestLine.text:GetFont();
	watchFrameTestLine.dash:SetText(QUEST_DASH);
	DASH_WIDTH = watchFrameTestLine.dash:GetWidth();
	WATCHFRAMELINES_FONTHEIGHT = fontHeight;
	WATCHFRAMELINES_FONTSPACING = (WATCHFRAME_LINEHEIGHT - WATCHFRAMELINES_FONTHEIGHT) / 2
	WatchFrame_AddObjectiveHandler(WatchFrameAutoQuest_DisplayAutoQuestPopUps);
	WatchFrame_AddObjectiveHandler(WatchFrame_HandleDisplayQuestTimers);
	WatchFrame_AddObjectiveHandler(WatchFrame_HandleDisplayTrackedAchievements);
	WatchFrame_AddObjectiveHandler(WatchFrame_DisplayTrackedQuests);
	WatchFrame.updateTimer = WATCHFRAME_UPDATE_RATE;
end

function WatchFrame_OnEvent (self, event, ...)
	if ( event == "PLAYER_MONEY" and self.watchMoney ) then
		WatchFrame_Update(self);
		if ( self.collapsed ) then
			UIFrameFlash(WatchFrameTitleButtonHighlight, .5, .5, 5, false);
		end
	elseif ( event == "QUEST_LOG_UPDATE" and not self.updating ) then -- May as well check here too and save some time
		if ( WatchFrame.showObjectives ) then
			WatchFrame_GetCurrentMapQuests();
		end	
		WatchFrame_Update(self);
		if ( self.collapsed ) then
			UIFrameFlash(WatchFrameTitleButtonHighlight, .5, .5, 5, false);
		end
	elseif ( event == "QUEST_POI_UPDATE" ) then
		if ( WatchFrame.showObjectives ) then
			WatchFrame_GetCurrentMapQuests();
		end		
		WatchFrame_Update(self);
	elseif ( event == "QUEST_ACCEPTED" ) then
		if ( WatchFrame.showObjectives ) then
			WatchFrame_GetCurrentMapQuests();
		end		
		WatchFrame_Update(self);
	elseif ( event == "TRACKED_ACHIEVEMENT_UPDATE" ) then
		local achievementID, criteriaID, elapsed, duration = ...;

		if ( not elapsed or not duration ) then
			-- Don't do anything
		elseif ( elapsed >= duration ) then
			WATCHFRAME_TIMEDCRITERIA[criteriaID] = nil;
		else
			local timedCriteria = WATCHFRAME_TIMEDCRITERIA[criteriaID] or {};
			timedCriteria.achievementID = achievementID;
			timedCriteria.startTime = GetTime() - elapsed;
			timedCriteria.duration = duration;
			WATCHFRAME_TIMEDCRITERIA[criteriaID] = timedCriteria;
		end

		if ( self.collapsed ) then
			UIFrameFlash(WatchFrameTitleButtonHighlight, .5, .5, 5, false);
		end

		WatchFrame_Update();
	elseif ( event == "ITEM_PUSH" ) then
		WatchFrame_Update();
	elseif ( event == "ZONE_CHANGED_NEW_AREA" ) then
		-- Set to a new zone, update
		WatchFrame_Update();
	elseif ( event == "DISPLAY_SIZE_CHANGED" ) then
		WatchFrame_OnSizeChanged(self);
	elseif ( event == "VARIABLES_LOADED" ) then
		WatchFrame_SetWidth(GetCVar("watchFrameWidth"));
		WATCHFRAME_SORT_TYPE = tonumber(GetCVar("trackerSorting"));
		WATCHFRAME_FILTER_TYPE = tonumber(GetCVar("trackerFilter"));
		-- WATCHFRAME_FILTER_TYPE = 4;
		-- WATCHFRAME_SORT_TYPE = 0;
	elseif ( event == "QUEST_AUTOCOMPLETE" ) then
		local questID = ...;
		if (WatchFrameAutoQuest_AddPopUp(questID, "COMPLETE")) then
			PlaySound(SOUNDKIT.UI_AUTO_QUEST_COMPLETE);
		end
	end
end

function WatchFrame_OnUpdate(self, elapsed)
	if ( WATCHFRAME_SORT_TYPE == WATCHFRAME_SORT_PROXIMITY ) then
		self.updateTimer = self.updateTimer - elapsed;
		if ( self.updateTimer < 0 ) then
			if ( SortQuestWatches() ) then
				WatchFrame_Update();
			end
			self.updateTimer = WATCHFRAME_UPDATE_RATE;
		end
	end
end

function WatchFrame_OnSizeChanged(self)
	WatchFrame_Update(self);
end

function WatchFrame_Collapse (self)
	self.collapsed = true;
	self:SetWidth(WATCHFRAME_COLLAPSEDWIDTH);
	WatchFrameLines:Hide();
	local button = WatchFrameCollapseExpandButton;
	local texture = button:GetNormalTexture();
	texture:SetTexCoord(0, 0.5, 0, 0.5);
	texture = button:GetPushedTexture();
	texture:SetTexCoord(0.5, 1, 0, 0.5);
end

function WatchFrame_Expand (self)
	self.collapsed = nil;
	self:SetWidth(WATCHFRAME_EXPANDEDWIDTH);
	WatchFrameLines:Show();
	local button = WatchFrameCollapseExpandButton;
	local texture = button:GetNormalTexture();
	texture:SetTexCoord(0, 0.5, 0.5, 1);
	texture = button:GetPushedTexture();
	texture:SetTexCoord(0.5, 1, 0.5, 1);
	WatchFrame_Update(self);
end

function GetTimerTextColor (duration, elapsed)
	local START_PERCENTAGE_YELLOW = .66
	local START_PERCENTAGE_RED = .33

	local percentageLeft = 1 - ( elapsed / duration )
	if ( percentageLeft > START_PERCENTAGE_YELLOW ) then
		return 1, 1, 1
	elseif ( percentageLeft > START_PERCENTAGE_RED ) then -- Start fading to yellow by eliminating blue
		local blueOffset = (percentageLeft - START_PERCENTAGE_RED) / (START_PERCENTAGE_YELLOW - START_PERCENTAGE_RED);
		return 1, 1, blueOffset;
	else
		local greenOffset = percentageLeft / START_PERCENTAGE_RED; -- Fade to red by eliminating green
		return 1, greenOffset, 0;
	end
end

function WatchFrame_ClearDisplay ()
	for _, timerLine in pairs(WATCHFRAME_TIMERLINES) do
		timerLine:Reset();
	end
	for _, achievementLine in pairs(WATCHFRAME_ACHIEVEMENTLINES) do
		achievementLine:Reset();
	end
	for _, questLine in pairs(WATCHFRAME_QUESTLINES) do
		questLine:Reset();
	end
	QuestPOI_HideAllButtons(WatchFrameLines);
end

function WatchFrame_Update (self)
	self = self or WatchFrame; -- Speeds things up if we pass in this reference when we can conveniently.
	-- Display things in this order: quest timers, achievements, quests, addon subscriptions.
	if ( self.updating ) then
		return;
	end

	self.updating = true;
	self.watchMoney = false;

	local nextAnchor = nil;
	local lineFrame = WatchFrameLines;
	local maxHeight = (WatchFrame:GetTop() - WatchFrame:GetBottom()); -- Can't use lineFrame:GetHeight() because it could be an invalid rectangle (width of 0)

	local maxFrameWidth = WATCHFRAME_MAXLINEWIDTH;
	local maxWidth = 0;
	local maxLineWidth;
	local numObjectives;
	local totalObjectives = 0;

	WatchFrame_ResetLinkButtons();
	QuestPOI_ResetUsage(WatchFrameLines);

	for i = 1, #WATCHFRAME_OBJECTIVEHANDLERS do
		nextAnchor, maxLineWidth, numObjectives = WATCHFRAME_OBJECTIVEHANDLERS[i](lineFrame, nextAnchor, maxHeight, maxFrameWidth);
		maxWidth = max(maxLineWidth, maxWidth);
		totalObjectives = totalObjectives + numObjectives

	end
	--disabled for now, might make it an option
	--lineFrame:SetWidth(min(maxWidth, maxFrameWidth));

	if ( totalObjectives > 0 ) then
		WatchFrameHeader:Show();
		WatchFrameCollapseExpandButton:Show();
		WatchFrameTitle:SetText(OBJECTIVES_TRACKER_LABEL.." ("..totalObjectives..")");
		WatchFrameHeader:SetWidth(WatchFrameTitle:GetWidth() + 4);
		-- visible objectives?
		if ( nextAnchor ) then
			if ( self.collapsed and not self.userCollapsed ) then
				-- Hacky, did this so the differences in remote zone filtering
				self.updating = nil;
				WatchFrame_Expand(self);
			end
			WatchFrameCollapseExpandButton:Enable();
		else
			if ( not self.collapsed ) then
				WatchFrame_Collapse(self);
			end
			WatchFrameCollapseExpandButton:Disable();
		end
	else
		WatchFrameHeader:Hide();
		WatchFrameCollapseExpandButton:Hide();
	end

	WatchFrame_ReleaseUnusedLinkButtons();

	self.updating = nil;
	self.nextOffset = totalOffset;
end

function WatchFrame_AddObjectiveHandler (func)
	local numFunctions = #WATCHFRAME_OBJECTIVEHANDLERS
	for i = 1, numFunctions do
		if ( WATCHFRAME_OBJECTIVEHANDLERS[i] == func ) then
			return;
		end
	end

	tinsert(WATCHFRAME_OBJECTIVEHANDLERS, func);
	return true;
end

function WatchFrame_RemoveObjectiveHandler (func)
	local numFunctions = #WATCHFRAME_OBJECTIVEHANDLERS
	for i = 1, numFunctions do
		if ( WATCHFRAME_OBJECTIVEHANDLERS[i] == func ) then
			tremove(WATCHFRAME_OBJECTIVEHANDLERS, i);
			return true;
		end
	end
end

function WatchFrame_HandleDisplayQuestTimers (lineFrame, nextAnchor, maxHeight, frameWidth)
	return WatchFrame_DisplayQuestTimers(lineFrame, nextAnchor, maxHeight, frameWidth, GetQuestTimers());
end

local timerLineIndex = 1;
local function WatchFrame_GetTimerLine ()
	local line = WATCHFRAME_TIMERLINES[timerLineIndex];
	if ( not line ) then
		WATCHFRAME_TIMERLINES[timerLineIndex] = WatchFrame.linePool:Acquire();
		line = WATCHFRAME_TIMERLINES[timerLineIndex];
	end

	line:Reset();
	timerLineIndex = timerLineIndex + 1;
	return line;
end

local function WatchFrame_ResetTimerLines ()
	timerLineIndex = 1;
end

local function WatchFrame_ReleaseUnusedTimerLines ()
	local line
	for i = timerLineIndex, #WATCHFRAME_TIMERLINES do
		line = WATCHFRAME_TIMERLINES[i];
		line:SetScript("OnEnter", nil);
		line:SetScript("OnLeave", nil);
		line:EnableMouse(false);
		WatchFrame.linePool:Release(line);
		WATCHFRAME_TIMERLINES[i] = nil;
	end
end

function WatchFrame_DisplayQuestTimers (lineFrame, nextAnchor, maxHeight, frameWidth, ...)
	local numTimers = select("#", ...);

	if ( numTimers == 0 ) then
		WatchFrame_ResetTimerLines();
		WatchFrame_ReleaseUnusedTimerLines();
		-- Nothing to see here, move along.
		if ( WATCHFRAME_NUM_TIMERS ~= 0 ) then
			WatchFrameLines_RemoveUpdateFunction(WatchFrame_HandleQuestTimerUpdate);
			WATCHFRAME_NUM_TIMERS = 0;
		end
		return nextAnchor, 0, 0;
	end

	WatchFrame_ResetTimerLines();

	local maxWidth = 0;
	local heightUsed = 0;
	local line = WatchFrame_GetTimerLine();
	line.text:SetText(NORMAL_FONT_COLOR_CODE .. QUEST_TIMERS);
	line:Show();
	line:SetPoint("RIGHT", lineFrame, "RIGHT", 0, 0);
	line:SetPoint("LEFT", lineFrame, "LEFT", 0, 0);
	if (nextAnchor) then
		line:SetPoint("TOP", nextAnchor, "BOTTOM", 0, -WATCHFRAME_TYPE_OFFSET);
	else
		line:SetPoint("TOP", lineFrame, "TOP", 0, -WATCHFRAME_INITIAL_OFFSET)
	end

	heightUsed = heightUsed + line:GetHeight();
	maxWidth = line.text:GetStringWidth();

	nextAnchor = line;

	for i = 1, numTimers do
		line = WatchFrame_GetTimerLine();
		line.text:SetText(" - " .. SecondsToTime(select(i, ...)));
		line:Show();
		line:SetPoint("RIGHT", lineFrame, "RIGHT", 0, 0);
		line:SetPoint("LEFT", lineFrame, "LEFT", 0, 0);
		line:SetPoint("TOP", nextAnchor, "BOTTOM", 0, 0);
		maxWidth = max(maxWidth, line.text:GetStringWidth());
		line:SetWidth(maxWidth) -- FIXME
		heightUsed = heightUsed + line:GetHeight();
		line:SetScript("OnEnter", function (self) GameTooltip:SetOwner(self); GameTooltip:SetHyperlink(GetQuestLink(GetQuestIDFromLogIndex(GetQuestIndexForTimer(i)))); GameTooltip:Show();  end);
		line:SetScript("OnLeave", GameTooltip_Hide);
		line:EnableMouse(true);
		nextAnchor = line;
	end

	if ( WATCHFRAME_NUM_TIMERS ~= numTimers ) then
		WATCHFRAME_NUM_TIMERS = numTimers;
		WatchFrameLines_AddUpdateFunction(WatchFrame_HandleQuestTimerUpdate);
	end

	WatchFrame_ReleaseUnusedTimerLines();
	return nextAnchor, maxWidth, 0;
end

function WatchFrame_HandleQuestTimerUpdate ()
	return WatchFrame_QuestTimerUpdateFunction(GetQuestTimers());
end

function WatchFrame_QuestTimerUpdateFunction (...)
	local numTimers = select("#", ...);

	if ( numTimers ~= WATCHFRAME_NUM_TIMERS ) then
		-- We need to update the entire watch frame, the number of displayed timers has changed.
		return true;
	end

	for i = 1, numTimers do
		local line = WATCHFRAME_TIMERLINES[i+1]; -- The first timer line is always the "Quest Timers" line, so skip it.
		local seconds = select(i, ...);
		line.text:SetText(" - " .. SecondsToTime(seconds));
	end
end

function WatchFrame_HandleDisplayTrackedAchievements (lineFrame, nextAnchor, maxHeight, frameWidth)
	return WatchFrame_DisplayTrackedAchievements(lineFrame, nextAnchor, maxHeight, frameWidth, GetTrackedAchievements());
end

function WatchFrame_UpdateTimedAchievements (elapsed)
	local numAchievementLines = #WATCHFRAME_ACHIEVEMENTLINES
	local timeNow, timeLeft;

	local needsUpdate = false;
	for i = 1, numAchievementLines do
		local line = WATCHFRAME_ACHIEVEMENTLINES[i];
		if ( line and line.criteriaID and WATCHFRAME_TIMEDCRITERIA[line.criteriaID] ) then
			timeNow = timeNow or GetTime();
			timeLeft = math.floor(line.startTime + line.duration - timeNow);
			if ( timeLeft <= 0 ) then
				line.text:SetText(string.format(" - " .. SECONDS_ABBR, 0));
				line.text:SetTextColor(1, 0, 0, 1);
			else
				line.text:SetText(" - " .. SecondsToTime(timeLeft));
				line.text:SetTextColor(GetTimerTextColor(line.duration, line.duration - timeLeft));
				needsUpdate = true;
			end
		end
	end

	if ( not needsUpdate ) then
		WatchFrameLines_RemoveUpdateFunction(WatchFrame_UpdateTimedAchievements);
	end
end

function WatchFrame_SetLine(line, anchor, verticalOffset, isHeader, text, dash, hasItem, isComplete)
	-- anchor
	if ( anchor ) then
		line:SetPoint("RIGHT", anchor, "RIGHT", 0, 0);
		line:SetPoint("LEFT", anchor, "LEFT", 0, 0);
		line:SetPoint("TOP", anchor, "BOTTOM", 0, verticalOffset);
	end
	-- text
	line.text:SetText(text);
	if ( isHeader ) then
		WATCHFRAME_SETLINES_NUMLINES = 0;
		line.text:SetTextColor(0.75, 0.61, 0);
	else
		--this should be the default, set in WatchFrameLineTemplate_Reset
	end
	-- dash
	local usedWidth = 0;
	if ( dash == DASH_SHOW ) then
		line.dash:SetText(QUEST_DASH);
		usedWidth = DASH_WIDTH;
	elseif ( dash == DASH_HIDE ) then
		line.dash:SetText(QUEST_DASH);
		line.dash:Hide();
		usedWidth = DASH_WIDTH;
	end
	-- multiple lines
	if ( hasItem and WATCHFRAME_SETLINES_NUMLINES < 2 ) then
		usedWidth = usedWidth + WATCHFRAME_ITEM_WIDTH;
	end
	line.text:SetWidth(WATCHFRAME_MAXLINEWIDTH - usedWidth);
	if ( line.text:GetHeight() > WATCHFRAME_LINEHEIGHT ) then
		if ( isComplete ) then
			line:SetHeight(line.text:GetHeight() + 4);
		else
			line:SetHeight(WATCHFRAME_MULTIPLE_LINEHEIGHT);
			line.text:SetHeight(WATCHFRAME_MULTIPLE_LINEHEIGHT);
		end
		WATCHFRAME_SETLINES_NUMLINES = WATCHFRAME_SETLINES_NUMLINES + 2;
	else
		WATCHFRAME_SETLINES_NUMLINES = WATCHFRAME_SETLINES_NUMLINES + 1;
	end
	tinsert(WATCHFRAME_SETLINES, line);
end

function WatchFrame_DisplayTrackedAchievements (lineFrame, nextAnchor, maxHeight, frameWidth, ...)
	local _; -- Doing this here thanks to IBLJerry!
	local numTrackedAchievements = select("#", ...);
	local line;
	local achievementTitle;
	local previousLine;
	local linkButton;

	local numCriteria, criteriaDisplayed;
	local achievementID, achievementName, completed, description, icon;
	local criteriaString, criteriaType, criteriaCompleted, quantity, totalQuantity, name, flags, assetID, quantityString, criteriaID, achievementCategory;
	local displayOnlyArena = ArenaEnemyFrames and ArenaEnemyFrames:IsShown();

	local lineWidth = 0;
	local maxWidth = 0;

	WatchFrame_ResetAchievementLines();
	if ( bit.band(WATCHFRAME_FILTER_TYPE, WATCHFRAME_FILTER_ACHIEVEMENTS) == WATCHFRAME_FILTER_ACHIEVEMENTS ) then
		for i = 1, numTrackedAchievements do
			WATCHFRAME_SETLINES = table.wipe(WATCHFRAME_SETLINES or { });
			achievementID = select(i, ...);
			achievementCategory = GetAchievementCategory(achievementID);
			_, achievementName, _, completed, _, _, _, description, _, icon = GetAchievementInfo(achievementID);
			if ( not completed and (not displayOnlyArena) or achievementCategory == WATCHFRAME_ACHIEVEMENT_ARENA_CATEGORY ) then
				-- achievement name
				line = WatchFrame_GetAchievementLine();
				achievementTitle = line;
				WatchFrame_SetLine(line, previousLine, -WATCHFRAME_QUEST_OFFSET, IS_HEADER, achievementName, DASH_NONE);
				if ( not previousLine ) then
					line:SetPoint("RIGHT", lineFrame, "RIGHT", 0, 0);
					line:SetPoint("LEFT", lineFrame, "LEFT", 0, 0);
					if (nextAnchor) then
						line:SetPoint("TOP", nextAnchor, "BOTTOM", 0, -WATCHFRAME_TYPE_OFFSET);
					else
						line:SetPoint("TOP", lineFrame, "TOP", 0, -WATCHFRAME_INITIAL_OFFSET);
					end
				end
				previousLine = line;
				-- criteria
				numCriteria = GetAchievementNumCriteria(achievementID);
				if ( numCriteria > 0 ) then
					criteriaDisplayed = 0;
					for j = 1, numCriteria do
						local dash = DASH_SHOW;		-- default since most will have this
						criteriaString, criteriaType, criteriaCompleted, quantity, totalQuantity, name, flags, assetID, quantityString, criteriaID = GetAchievementCriteriaInfo(achievementID, j);
						if ( criteriaCompleted or ( criteriaDisplayed > WATCHFRAME_CRITERIA_PER_ACHIEVEMENT and not criteriaCompleted ) ) then
							-- Do not display this one
							criteriaString = nil;
							dash = DASH_NONE;
						elseif ( criteriaDisplayed == WATCHFRAME_CRITERIA_PER_ACHIEVEMENT ) then
							-- We ran out of space to display incomplete criteria >_<
							criteriaString = "...";
							dash = DASH_HIDE;
						else
							if ( WATCHFRAME_TIMEDCRITERIA[criteriaID] ) then
								-- not sure what this is for
								local timedCriteria = WATCHFRAME_TIMEDCRITERIA[criteriaID]
								line = WatchFrame_GetAchievementLine();
								line.criteriaID = criteriaID;
								line.duration = timedCriteria.duration;
								line.startTime = timedCriteria.startTime;
								WatchFrame_SetLine(line, previousLine, WATCHFRAMELINES_FONTSPACING, not IS_HEADER, "<???>", DASH_NONE);
								previousLine = line;
								criteriaDisplayed = criteriaDisplayed + 1;
								WatchFrameLines_AddUpdateFunction(WatchFrame_UpdateTimedAchievements);
							end
							if ( bit.band(flags, ACHIEVEMENT_CRITERIA_PROGRESS_BAR) == ACHIEVEMENT_CRITERIA_PROGRESS_BAR ) then
								-- progress bar
								criteriaString = quantityString;
							else
								-- regular criteria
								-- no need to do anything, criteriaString and dash are already set
							end
						end
						-- set up the line
						if ( criteriaString ) then
							line = WatchFrame_GetAchievementLine();
							WatchFrame_SetLine(line, previousLine, WATCHFRAMELINES_FONTSPACING, not IS_HEADER, criteriaString, dash);
							previousLine = line;
							criteriaDisplayed = criteriaDisplayed + 1;
						end
					end
				else
					-- single criteria type of achievement
					line = WatchFrame_GetAchievementLine();
					WatchFrame_SetLine(line, previousLine, WATCHFRAMELINES_FONTSPACING, not IS_HEADER, description, DASH_SHOW);
					previousLine = line;
					for timedCriteriaID, timedCriteria in next, WATCHFRAME_TIMEDCRITERIA do
						if ( timedCriteria.achievementID == achievementID ) then
							-- not sure what this is for
							line = WatchFrame_GetAchievementLine();
							line.criteriaID = timedCriteriaID;
							line.duration = timedCriteria.duration;
							line.startTime = timedCriteria.startTime;
							WatchFrame_SetLine(line, previousLine, WATCHFRAMELINES_FONTSPACING, not IS_HEADER, "<???>", DASH_NONE)
							previousLine = line;
							WatchFrameLines_AddUpdateFunction(WatchFrame_UpdateTimedAchievements);
						end
					end
				end

				-- stop processing if there's no room to fit the achievement
				local numLines = #WATCHFRAME_SETLINES;
				local previousBottom = previousLine:GetBottom();
				if ( previousBottom and previousBottom < WatchFrame:GetBottom() ) then
					achievementLineIndex = achievementLineIndex - numLines;
					table.wipe(WATCHFRAME_SETLINES);
					break;
				else
					-- turn on all lines
					for _, lineFrameToShow in pairs(WATCHFRAME_SETLINES) do
						lineFrameToShow:Show();
						lineWidth = lineFrameToShow.text:GetWidth() + lineFrameToShow.dash:GetWidth();
						maxWidth = max(maxWidth, lineWidth);
					end
					-- turn on link button
					linkButton = WatchFrame_GetLinkButton();
					linkButton:SetPoint("TOPLEFT", achievementTitle.text);
					linkButton:SetPoint("BOTTOMLEFT", achievementTitle.text);
					linkButton:SetWidth(achievementTitle.text:GetStringWidth());
					linkButton.type = "ACHIEVEMENT";
					linkButton.index = achievementID;
					linkButton.lines = WATCHFRAME_ACHIEVEMENTLINES;
					linkButton.startLine = achievementLineIndex - numLines;
					linkButton.lastLine = achievementLineIndex - 1;
					linkButton.isComplete = nil;
					linkButton:Show();
				end
			end
		end
	end

	WatchFrame_ReleaseUnusedAchievementLines();
	return previousLine or nextAnchor, maxWidth, numTrackedAchievements;
end

function WatchFrame_DisplayTrackedQuests (lineFrame, nextAnchor, maxHeight, frameWidth)
	local _;
	local questTitle;
	local questIndex;
	local line;
	local lastLine;
	local linkButton;
	local watchItemIndex = 0;
	local numVisible = 0;

	local numPOINumeric = 0;
	local numPOICompleteIn = 0;
	local numPOICompleteOut = 0;

	local text, finished;
	local numQuestWatches = GetNumQuestWatches();
	local numObjectives;
	local title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID;
	local frequency, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling;

	local maxWidth = 0;
	local lineWidth = 0;

	local playerMoney = GetMoney();
	local selectedQuestId;
	if ( WorldMapFrame and WorldMapFrame:IsShown() ) then
		selectedQuestId = QuestMapFrame_GetFocusedQuestID();
	end
	-- Set our current zone
	local currentZone = C_Map.GetBestMapForUnit("player");
	-- For the filter REMOTE ZONES: when it's unchecked we need to display local POIs only. Unfortunately all the POI
	-- code uses the current map so the tracker would not display the right quests if the world map was windowed and
	-- open to a different zone.
	table.wipe(LOCAL_MAP_QUESTS);
	LOCAL_MAP_QUESTS["zone"] = currentZone;
	for id in pairs(CURRENT_MAP_QUESTS) do
		LOCAL_MAP_QUESTS[id] = true;
	end	
	
	table.wipe(VISIBLE_WATCHES);
	WatchFrame_ResetQuestLines();

	for i = 1, numQuestWatches do
		WATCHFRAME_SETLINES = table.wipe(WATCHFRAME_SETLINES or { });
		questIndex = GetQuestIndexForWatch(i);
		if ( questIndex ) then
			title, level, questTag, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling = GetQuestLogTitle(questIndex);
			local questFailed = false;
			local requiredMoney = GetQuestLogRequiredMoney(questIndex);
			numObjectives = GetNumQuestLeaderBoards(questIndex);
			if ( isComplete and isComplete < 0 ) then
				isComplete = false;
				questFailed = true;
			elseif ( numObjectives == 0 and playerMoney >= requiredMoney ) then
				isComplete = true;
			end
			-- check filters
			local filterOK = true;
			if ( isComplete and bit.band(WATCHFRAME_FILTER_TYPE, WATCHFRAME_FILTER_COMPLETED_QUESTS) ~= WATCHFRAME_FILTER_COMPLETED_QUESTS ) then
				filterOK = false;
			elseif ( bit.band(WATCHFRAME_FILTER_TYPE, WATCHFRAME_FILTER_REMOTE_ZONES) ~= WATCHFRAME_FILTER_REMOTE_ZONES and currentZone ~= GetQuestUiMapID(questID) and not LOCAL_MAP_QUESTS[questID]) then
				filterOK = false;
			end

			if ( filterOK ) then
				local link, item, charges, showItemWhenComplete = GetQuestLogSpecialItemInfo(questIndex);
				if ( requiredMoney > 0 ) then
					WatchFrame.watchMoney = true;	-- for update event
				end
				questTitle = WatchFrame_GetQuestLine();
				if displayQuestID then
					title = questID .. " - " .. title;
				end
				WatchFrame_SetLine(questTitle, lastLine, -WATCHFRAME_QUEST_OFFSET, IS_HEADER, title, DASH_NONE, item);
				if ( not lastLine ) then -- First line
					questTitle:SetPoint("RIGHT", lineFrame, "RIGHT", 0, 0);
					questTitle:SetPoint("LEFT", lineFrame, "LEFT", 0, 0);
					if (nextAnchor) then
						questTitle:SetPoint("TOP", nextAnchor, "BOTTOM", 0, -WATCHFRAME_TYPE_OFFSET);
					else
						questTitle:SetPoint("TOP", lineFrame, "TOP", 0, -WATCHFRAME_INITIAL_OFFSET);
					end
				end
				lastLine = questTitle;

				if ( isComplete ) then
					local showItem = item and showItemWhenComplete;
					if (GetQuestLogIsAutoComplete(questIndex)) then
						line = WatchFrame_GetQuestLine();
						WatchFrame_SetLine(line, lastLine, WATCHFRAMELINES_FONTSPACING, not IS_HEADER, QUEST_WATCH_QUEST_COMPLETE, DASH_HIDE, showItem, true);
						lastLine = line;
						line = WatchFrame_GetQuestLine();
						WatchFrame_SetLine(line, lastLine, WATCHFRAMELINES_FONTSPACING, not IS_HEADER, QUEST_WATCH_CLICK_TO_COMPLETE, DASH_HIDE, showItem, true);
						lastLine = line;
					else
						line = WatchFrame_GetQuestLine();
						WatchFrame_SetLine(line, lastLine, WATCHFRAMELINES_FONTSPACING, not IS_HEADER, GetQuestLogCompletionText(questIndex), DASH_SHOW, nil, true);
						lastLine = line;
					end
				elseif ( questFailed ) then
					line = WatchFrame_GetQuestLine();
					WatchFrame_SetLine(line, lastLine, WATCHFRAMELINES_FONTSPACING, not IS_HEADER, FAILED, DASH_HIDE, nil, nil, false);
					lastLine = line;
				else
					-- Could have some objectives that caused our first isComplete to return nil
					-- Check if we have any hidden objectives that aren't normally tracked by checking text
					local hiddenObjective = nil;
					local uncompletedObjectives = nil;
					for j = 1, numObjectives do
						text, _, finished = GetQuestLogLeaderBoard(j, questIndex);
						if ( not finished and text) then
							text = WatchFrame_ReverseQuestObjective(text);
							line = WatchFrame_GetQuestLine();
							WatchFrame_SetLine(line, lastLine, WATCHFRAMELINES_FONTSPACING, not IS_HEADER, text, DASH_SHOW, item);
							lastLine = line;
							uncompletedObjectives = true;
						elseif(not finished and not text) then
							hiddenObjective = true;
						end
					end
					if (hiddenObjective and not uncompletedObjectives) then
						line = WatchFrame_GetQuestLine();
						WatchFrame_SetLine(line, lastLine, WATCHFRAMELINES_FONTSPACING, not IS_HEADER, GetQuestLogCompletionText(questIndex), DASH_SHOW, nil, true);
						lastLine = line;
					end
					if ( requiredMoney > playerMoney ) then
						text = GetMoneyString(playerMoney).." / "..GetMoneyString(requiredMoney);
						line = WatchFrame_GetQuestLine();
						WatchFrame_SetLine(line, lastLine, WATCHFRAMELINES_FONTSPACING, not IS_HEADER, text, DASH_SHOW, item);
						lastLine = line;
					end
				end

				-- stop processing if there's no room to fit the quest
				local numLines = #WATCHFRAME_SETLINES;
				local lastBottom = lastLine:GetBottom();
				if ( lastBottom and lastBottom < WatchFrame:GetBottom() ) then
					questLineIndex = questLineIndex - numLines;
					table.wipe(WATCHFRAME_SETLINES);
					break;
				end

				numVisible = numVisible + 1;
				table.insert(VISIBLE_WATCHES, numVisible, questIndex);		-- save the quest log index because watch order can change after dropdown is opened
				-- turn on quest item
				local itemButton;
				if ( item and (not isComplete or showItemWhenComplete) ) then
					watchItemIndex = watchItemIndex + 1;
					itemButton = _G["WatchFrameItem"..watchItemIndex];
					if ( not itemButton ) then
						WATCHFRAME_NUM_ITEMS = watchItemIndex;
						itemButton = CreateFrame("BUTTON", "WatchFrameItem" .. watchItemIndex, lineFrame, "WatchFrameItemButtonTemplate");
					end
					itemButton:Show();
					itemButton:ClearAllPoints();
					itemButton:SetID(questIndex);
					SetItemButtonTexture(itemButton, item);
					SetItemButtonCount(itemButton, charges);
					itemButton.charges = charges;
					WatchFrameItem_UpdateCooldown(itemButton);
					itemButton.rangeTimer = -1;
					itemButton:SetPoint("TOPRIGHT", questTitle, "TOPRIGHT", 10, -2);
				end
				-- turn on all lines
				for _, lineFrameToShow in pairs(WATCHFRAME_SETLINES) do
					lineFrameToShow:Show();
					lineWidth = lineFrameToShow.text:GetWidth() + lineFrameToShow.dash:GetWidth();
					maxWidth = max(maxWidth, lineWidth);
				end
				-- turn on link button
				linkButton = WatchFrame_GetLinkButton();
				linkButton:SetPoint("TOPLEFT", questTitle);
				linkButton:SetPoint("BOTTOMLEFT", questTitle);
				linkButton:SetPoint("RIGHT", questTitle.text);
				linkButton.type = "QUEST"
				linkButton.index = i; -- We want the Watch index, we'll get the quest index later with GetQuestIndexForWatch(i);
				linkButton.lines = WATCHFRAME_QUESTLINES;
				linkButton.startLine = questLineIndex - numLines;
				linkButton.lastLine = questLineIndex - 1;
				linkButton.isComplete = isComplete;
				linkButton:Show();
				-- quest POI icon
				if ( WatchFrame.showObjectives ) then
					local poiButton;
					if ( LOCAL_MAP_QUESTS[questID] ) then
						if ( isComplete ) then
							numPOICompleteIn = numPOICompleteIn + 1;
							poiButton = QuestPOI_GetButton(WatchFrameLines, questID, "completed", numPOICompleteIn);
						else
							numPOINumeric = numPOINumeric + 1;
							poiButton = QuestPOI_GetButton(WatchFrameLines, questID, "numeric", numPOINumeric);
						end
					elseif ( isComplete ) then
						numPOICompleteOut = numPOICompleteOut + 1;
						poiButton = QuestPOI_GetButton(WatchFrameLines, questID, "completed", numPOICompleteOut);
					end
					if ( poiButton ) then
						poiButton:SetPoint("TOPRIGHT", questTitle, "TOPLEFT", 0, 5);
					end				
				end

			end
		end
	end

	for i = watchItemIndex + 1, WATCHFRAME_NUM_ITEMS do
		_G["WatchFrameItem" .. i]:Hide();
	end

	WatchFrame_ReleaseUnusedQuestLines();

	QuestPOI_HideUnusedButtons(WatchFrameLines);

	if ( selectedQuestId ) then
		QuestPOI_SelectButtonByQuestID(WatchFrameLines, selectedQuestId);	
	end

	return lastLine or nextAnchor, maxWidth, numQuestWatches;
end

function WatchFrameLines_OnUpdate (self, elapsed)
	for i = 1, self.numFunctions do
		if ( self.updateFunctions[i](elapsed) ) then -- If a function returns true, update the entire watch frame (the number of lines changed).
			WatchFrame_Update(WatchFrame);
			return;
		end
	end
end

function WatchFrameLines_AddUpdateFunction (func)
	local self = WatchFrameLines;
	local numFunctions = self.numFunctions
	for i = 1, numFunctions do
		if ( self.updateFunctions[i] == func ) then
			return;
		end
	end

	tinsert(self.updateFunctions, func);
	self.numFunctions = self.numFunctions + 1;
	self:SetScript("OnUpdate", WatchFrameLines_OnUpdate);
end

function WatchFrameLines_RemoveUpdateFunction (func)
	local self = WatchFrameLines;
	local numFunctions = WatchFrameLines.numFunctions
	for i = 1, numFunctions do
		if ( self.updateFunctions[i] == func ) then
			tremove(self.updateFunctions, i);
			self.numFunctions = self.numFunctions - 1;
			break;
		end
	end

	if ( self.numFunctions == 0 ) then
		self:SetScript("OnUpdate", nil);
	end
end

function WatchFrame_OpenQuestLog (button, arg1, arg2, checked)
	ExpandQuestHeader(GetQuestIndexForWatch(arg1));
	-- you have to call GetQuestIndexForWatch again because ExpandQuestHeader will sort the indices
	QuestLog_OpenToQuest(GetQuestIndexForWatch(arg1), arg2);
end

function WatchFrame_AbandonQuest (button, arg1, arg2, checked)
	local lastQuest = GetQuestLogSelection();
	local lastNumQuests = GetNumQuestLogEntries();
	SelectQuestLogEntry(GetQuestIndexForWatch(arg1)); -- More or less QuestLogFrameAbandonButton_OnClick, may want to consolidate
	SetAbandonQuest();

	local items = GetAbandonQuestItems();
	if ( items ) then
		StaticPopup_Hide("ABANDON_QUEST");
		StaticPopup_Show("ABANDON_QUEST_WITH_ITEMS", GetAbandonQuestName(), items);
	else
		StaticPopup_Hide("ABANDON_QUEST_WITH_ITEMS");
		StaticPopup_Show("ABANDON_QUEST", GetAbandonQuestName());
	end
	SelectQuestLogEntry(lastQuest);
end

function WatchFrame_ShareQuest (button, arg1, arg2, checked)
	QuestLogPushQuest(GetQuestIndexForWatch(arg1));
end

function WatchFrame_StopTrackingQuest (button, arg1, arg2, checked)
	RemoveQuestWatch(GetQuestIndexForWatch(arg1));
	WatchFrame_Update();
	QuestLog_Update();
end

function WatchFrame_OpenMapToQuest (button, arg1)
	local index = GetQuestIndexForWatch(arg1);
	local questID = select(8, GetQuestLogTitle(index));
	QuestMapFrame_OpenToQuestDetails(questID);
end

function WatchFrame_OpenAchievementFrame (button, arg1, arg2, checked)
	if ( not AchievementFrame ) then
		AchievementFrame_LoadUI();
	end

	if ( not AchievementFrame:IsShown() ) then
		AchievementFrame_ToggleAchievementFrame();
		AchievementFrame_SelectAchievement(arg1);
	else
		if ( AchievementFrameAchievements.selection ~= arg1 ) then
			AchievementFrame_SelectAchievement(arg1);
		else
			AchievementFrame_ToggleAchievementFrame();
		end
	end
end

function WatchFrame_StopTrackingAchievement (button, arg1, arg2, checked)
	RemoveTrackedAchievement(arg1);
	WatchFrame_Update();
	if ( AchievementFrame ) then
		AchievementFrameAchievements_ForceUpdate(); -- Quests handle this automatically because they have spiffy events.
	end
end

function WatchFrame_CollapseExpandButton_OnClick (self)
	local WatchFrame = WatchFrame;
	if ( WatchFrame.collapsed ) then
		WatchFrame.userCollapsed = nil;
		WatchFrame_Expand(WatchFrame);
		PlaySound(SOUNDKIT.IG_MINIMAP_OPEN);
		-- PlaySound("igMiniMapOpen");
	else
		WatchFrame.userCollapsed = true;
		WatchFrame_Collapse(WatchFrame);
		PlaySound(SOUNDKIT.IG_MINIMAP_CLOSE);
		-- PlaySound("igMiniMapClose");
	end
end

local function WatchFrameLineTemplate_Reset (self)
	self:ClearAllPoints();
	self.text:SetText("");
	self.text:SetTextColor(0.8, 0.8, 0.8);
	self.text:Show();
	self.dash:SetText(nil);
	self.dash:Show();
	self:SetHeight(WATCHFRAME_LINEHEIGHT);
	self.text:SetHeight(0);
	self.criteriaID = nil;
end

function WatchFrameLineTemplate_OnLoad (self)
	local name = self:GetName();
	self.Reset = WatchFrameLineTemplate_Reset;
end

function WatchFrameItem_UpdateCooldown (self)
	local itemCooldown = _G[self:GetName().."Cooldown"];
	local start, duration, enable = GetQuestLogSpecialItemCooldown(self:GetID());
	CooldownFrame_Set(itemCooldown, start, duration, enable);
	if ( duration > 0 and enable == 0 ) then
		SetItemButtonTextureVertexColor(self, 0.4, 0.4, 0.4);
	else
		SetItemButtonTextureVertexColor(self, 1, 1, 1);
	end
end

function WatchFrameItem_OnLoad (self)
	self:RegisterForClicks("AnyUp");
end

function WatchFrameItem_OnEvent (self, event, ...)
	if ( event == "PLAYER_TARGET_CHANGED" ) then
		self.rangeTimer = -1;
	elseif ( event == "BAG_UPDATE_COOLDOWN" ) then
		WatchFrameItem_UpdateCooldown(self);
	end
end

function WatchFrameItem_OnUpdate (self, elapsed)
	-- Handle range indicator
	local rangeTimer = self.rangeTimer;
	if ( rangeTimer ) then
		rangeTimer = rangeTimer - elapsed;
		if ( rangeTimer <= 0 ) then
			local link, item, charges, showItemWhenComplete = GetQuestLogSpecialItemInfo(self:GetID());
			if ( not charges or charges ~= self.charges ) then
				WatchFrame_Update();
				return;
			end
			local count = _G[self:GetName().."HotKey"];
			local valid = IsQuestLogSpecialItemInRange(self:GetID());
			if ( valid == 0 ) then
				count:Show();
				count:SetVertexColor(1.0, 0.1, 0.1);
			elseif ( valid == 1 ) then
				count:Show();
				count:SetVertexColor(0.6, 0.6, 0.6);
			else
				count:Hide();
			end
			rangeTimer = TOOLTIP_UPDATE_TIME;
		end

		self.rangeTimer = rangeTimer;
	end
end

function WatchFrameItem_OnShow (self)
	self:RegisterEvent("PLAYER_TARGET_CHANGED");
	self:RegisterEvent("BAG_UPDATE_COOLDOWN");
end

function WatchFrameItem_OnHide (self)
	self:UnregisterEvent("PLAYER_TARGET_CHANGED");
	self:UnregisterEvent("BAG_UPDATE_COOLDOWN");
end

function WatchFrameItem_OnEnter (self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetQuestLogSpecialItem(self:GetID());
end

function WatchFrameItem_OnClick (self, button, down)
	local questIndex = self:GetID();
	if ( IsModifiedClick("CHATLINK") and ChatEdit_GetActiveWindow() ) then
		local link, item, charges, showItemWhenComplete = GetQuestLogSpecialItemInfo(questIndex);
		if ( link ) then
			ChatEdit_InsertLink(link);
		end
	else
		UseQuestLogSpecialItem(questIndex);
	end
end

function WatchFrame_ReverseQuestObjective(text)
	local _, _, arg1, arg2 = string.find(text, "(.*):%s(.*)");
	if ( arg1 and arg2 ) then
		return arg2.." "..arg1;
	else
		return text;
	end
end

function WatchFrameLinkButtonTemplate_Highlight(self, onEnter)
	local line;
	for index = self.startLine, self.lastLine do
		line = self.lines[index];
		if ( line ) then
			if ( index == self.startLine ) then
				-- header
				if ( onEnter ) then
					line.text:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
				else
					line.text:SetTextColor(0.75, 0.61, 0);
				end
			else
				if ( onEnter ) then
					line.text:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
					line.dash:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
				else
					line.text:SetTextColor(0.8, 0.8, 0.8);
					line.dash:SetTextColor(0.8, 0.8, 0.8);
				end
			end
		end
	end
	if(self.index) then
		local questIndex = GetQuestIndexForWatch(self.index);
		EventRegistry:TriggerEvent("WatchFrame.MouseOver", self, questIndex);
	end
end

function WatchFrame_GetCurrentMapQuests()
	local numQuests = QuestMapUpdateAllQuests();
	table.wipe(CURRENT_MAP_QUESTS);	
	for i = 1, numQuests do
		local questID = QuestPOIGetQuestIDByVisibleIndex(i);
		CURRENT_MAP_QUESTS[questID] = i;
	end
end

function WatchFrameQuestPOI_OnClick(self, button)
	QuestPOI_SelectButtonByQuestId(WatchFrameLines, self.questID);
	if ( WorldMapFrame:IsShown() ) then
		WorldMapFrame_SelectQuestById(self.questID);
		QuestPOI_SelectButtonByQuestID(WorldMapFrame, self.questID)
	end
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
end

function WatchFrame_SetWidth(width)
	if ( width == "0" ) then
		WATCHFRAME_EXPANDEDWIDTH = 204;
		WATCHFRAME_MAXLINEWIDTH = 192;
	else
		WATCHFRAME_EXPANDEDWIDTH = 306;
		WATCHFRAME_MAXLINEWIDTH = 294;
	end
	if ( WatchFrame:IsShown() and not WatchFrame.collapsed ) then
		WatchFrame:SetWidth(WATCHFRAME_EXPANDEDWIDTH);
		WatchFrame_Update();
	end
end

local function IsSortSelected(sortType)
	return WATCHFRAME_SORT_TYPE == sortType;
end

local function SetSortSelected(sortType)
	WatchFrame_SetSorting(sortType);
end

local function CreateSortRadio(rootDescription, text, tooltipText, sortType)
	local radio = rootDescription:CreateRadio(text, IsSortSelected, SetSortSelected, sortType);
	radio:SetTooltip(function(tooltip, elementDescription)
		GameTooltip_SetTitle(tooltip, text);
		GameTooltip_AddNormalLine(tooltip, tooltipText);
	end);
end

local function IsFilterSelected(filterType)
	return bit.band(WATCHFRAME_FILTER_TYPE, filterType) == filterType;
end

local function SetFilterSelected(filterType)
	WatchFrame_SetFilter(filterType);
end

local function CreateFilterRadio(rootDescription, text, tooltipText, filterType)
	local radio = rootDescription:CreateRadio(text, IsFilterSelected, SetFilterSelected, filterType);
	radio:SetTooltip(function(tooltip, elementDescription)
		GameTooltip_SetTitle(tooltip, text);
		GameTooltip_AddNormalLine(tooltip, tooltipText);
	end);
end

function WatchFrameHeader_OnClick(self, button)
	if ( button == "RightButton" ) then
		MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
			rootDescription:SetTag("MENU_WATCH_FRAME_HEADER");

			rootDescription:CreateTitle(TRACKER_SORT_LABEL);
			CreateSortRadio(rootDescription, TRACKER_SORT_DIFFICULTY_HIGH, TOOLTIP_TRACKER_SORT_DIFFICULTY_HIGH, WATCHFRAME_SORT_DIFFICULTY_HIGH);
			CreateSortRadio(rootDescription, TRACKER_SORT_DIFFICULTY_LOW, TOOLTIP_TRACKER_SORT_DIFFICULTY_LOW, WATCHFRAME_SORT_DIFFICULTY_LOW);
			CreateSortRadio(rootDescription, TRACKER_SORT_MANUAL, TOOLTIP_TRACKER_SORT_MANUAL, WATCHFRAME_SORT_MANUAL);

			rootDescription:CreateTitle(TRACKER_FILTER_LABEL);
			CreateFilterRadio(rootDescription, TRACKER_FILTER_ACHIEVEMENTS, TOOLTIP_TRACKER_FILTER_ACHIEVEMENTS, WATCHFRAME_FILTER_ACHIEVEMENTS);
			CreateFilterRadio(rootDescription, TRACKER_FILTER_COMPLETED_QUESTS, TOOLTIP_TRACKER_FILTER_COMPLETED_QUESTS, WATCHFRAME_FILTER_COMPLETED_QUESTS);
			CreateFilterRadio(rootDescription, TRACKER_FILTER_REMOTE_ZONES, TOOLTIP_TRACKER_FILTER_REMOTE_ZONES, WATCHFRAME_FILTER_REMOTE_ZONES);

		end);
	end
end

function WatchFrame_SetSorting(button, arg1)
	WATCHFRAME_SORT_TYPE = arg1;
	SetCVar("trackerSorting", WATCHFRAME_SORT_TYPE);
	if ( WATCHFRAME_SORT_TYPE ~= WATCHFRAME_SORT_MANUAL ) then
		SortQuestWatches();
		WatchFrame_Update();
		WatchFrame.updateTimer = WATCHFRAME_UPDATE_RATE;
	end
end

function WatchFrame_SetFilter(button, arg1)
	if ( bit.band(WATCHFRAME_FILTER_TYPE, arg1) == arg1 ) then
		WATCHFRAME_FILTER_TYPE = WATCHFRAME_FILTER_TYPE - arg1;
	else
		WATCHFRAME_FILTER_TYPE = WATCHFRAME_FILTER_TYPE + arg1;
	end
	SetCVar("trackerFilter", WATCHFRAME_FILTER_TYPE);
	WatchFrame_Update();
end

function WatchFrame_GetVisibleIndex(questLogIndex)
	for i = 1, #VISIBLE_WATCHES do
		if ( VISIBLE_WATCHES[i] == questLogIndex ) then
			return i;
		end
	end
end

function WatchFrame_MoveQuest(button, questLogIndex, numMoves)
	if ( WATCHFRAME_SORT_TYPE ~= WATCHFRAME_SORT_MANUAL ) then
		WatchFrame_SetSorting(nil, WATCHFRAME_SORT_MANUAL);
		UIErrorsFrame:AddMessage(TRACKER_SORT_MANUAL_WARNING, 1.0, 1.0, 0.0, 1.0);
	end
	local numVisibleWatches = #VISIBLE_WATCHES;
	local indexStart = WatchFrame_GetVisibleIndex(questLogIndex);
	local indexEnd = indexStart + numMoves;
	if ( indexEnd < 1 ) then
		indexEnd = 1;
	elseif ( indexEnd > numVisibleWatches ) then
		indexEnd = numVisibleWatches;
	end
	ShiftQuestWatches(GetQuestWatchIndex(questLogIndex), GetQuestWatchIndex(VISIBLE_WATCHES[indexEnd]));
	WatchFrame_Update();
end

-- AutoQuest pop-ups
local numPopUpFrames = 0;

function WatchFrameAutoQuest_GetOrCreateFrame(parent, index)
	if (_G["WatchFrameAutoQuestPopUp"..index]) then
		return _G["WatchFrameAutoQuestPopUp"..index];
	end
	local frame = CreateFrame("SCROLLFRAME", "WatchFrameAutoQuestPopUp"..index, parent, "WatchFrameAutoQuestPopUpTemplate");	
	frame.index = index;
	numPopUpFrames = numPopUpFrames+1;
	return frame;
end

function WatchFrameAutoQuest_DisplayAutoQuestPopUps(lineFrame, nextAnchor, maxHeight, frameWidth)
	local numPopUps = 0;
	local maxWidth = 0;
	local numAutoQuestPopUps = GetNumAutoQuestPopUps();
	for i=1, numAutoQuestPopUps do
		local questID, popUpType = GetAutoQuestPopUp(i);
		local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, _ = GetQuestLogTitle(GetQuestLogIndexByID(questID));
				
		if ( isComplete and isComplete > 0 ) then
			isComplete = true;
		else
			isComplete = false;
		end	
			
		if (questTitle and questTitle ~= "") then
			local frame = WatchFrameAutoQuest_GetOrCreateFrame(lineFrame, numPopUps+1);
			frame:Show();
			frame:ClearAllPoints();
			frame:SetParent(lineFrame);
			
			if (not frame.questID) then
				-- Only show the animation for new notifications
				frame.ScrollChild.Flash:Hide();
				WatchFrameAutoQuest_SlideIn(frame, 0.4);
			end
			
			if (isComplete and popUpType == "COMPLETE") then
				frame.ScrollChild.QuestionMark:Show();
				frame.ScrollChild.Exclamation:Hide();
				frame.ScrollChild.TopText:SetText(QUEST_WATCH_POPUP_CLICK_TO_COMPLETE);
				frame.ScrollChild.BottomText:Hide();
				frame.ScrollChild.TopText:SetPoint("TOP", 0, -12);
				frame.ScrollChild.QuestName:SetPoint("TOP", 0, -32);
				if (frame.questID and frame.type=="OFFER") then
					frame.ScrollChild.Flash:Show();
				end
				frame.type="COMPLETED";
			elseif (popUpType == "OFFER") then
				frame.ScrollChild.QuestionMark:Hide();
				frame.ScrollChild.Exclamation:Show();
				frame.ScrollChild.TopText:SetText(QUEST_WATCH_POPUP_QUEST_DISCOVERED);
				frame.ScrollChild.BottomText:Show();
				frame.ScrollChild.BottomText:SetText(QUEST_WATCH_POPUP_CLICK_TO_VIEW);
				frame.ScrollChild.TopText:SetPoint("TOP", 0, -4);
				frame.ScrollChild.QuestName:SetPoint("TOP", 0, -24);
				frame.ScrollChild.Flash:Hide();
				frame.type="OFFER";
			end
			
			frame:ClearAllPoints();
			if (nextAnchor) then
				if (i == 1) then
					frame:SetPoint("TOP", nextAnchor, "BOTTOM", 0, -WATCHFRAME_TYPE_OFFSET);
				else
					frame:SetPoint("TOP", nextAnchor, "BOTTOM", 0, 0);
				end
			else
				-- Cancel out the WATCHFRAME_TYPE_OFFSET here, it will be added into the animation for the first pop-up.  Also add 1 for the initial height of the pop-up.
				-- This prevents tracked quests from moving a bit initially while the background shadow is fading in.
				frame:SetPoint("TOP", lineFrame, "TOP", 0, -WATCHFRAME_INITIAL_OFFSET+WATCHFRAME_TYPE_OFFSET+1);
			end
			frame:SetPoint("LEFT", lineFrame, "LEFT", -30, 0);

			frame.ScrollChild.QuestName:SetText(questTitle);
			frame.questID = questID;
			
			maxWidth = max(maxWidth, frame:GetWidth());
			nextAnchor = frame;
			numPopUps = numPopUps+1;
		end
	end
	
	for i=numPopUps+1, numPopUpFrames do
		_G["WatchFrameAutoQuestPopUp"..i].questID = nil;
		_G["WatchFrameAutoQuestPopUp"..i]:Hide();
	end
	
	if (numPopUps > 0) then
		if (not lineFrame.AutoQuestShadow:IsShown()) then
			lineFrame.AutoQuestShadow:Show();
			lineFrame.AutoQuestShadow.FadeIn:Play();
		end
	else
		lineFrame.AutoQuestShadow:Hide();
	end
	
	return nextAnchor, maxWidth, 0;
end

function WatchFrameAutoQuest_OnUpdate(frame, timestep)
	local height = 72;
	local scrollStart = 65;
	local scrollEnd = -9;
	
	-- Pause animation while the AutoQuestShadow is animating
	if (WatchFrameLinesAutoQuestShadow.FadeIn:IsPlaying()) then
		return;
	end
	
	-- The first pop-up needs to include the WATCHFRAME_TYPE_OFFSET in the animation
	if (frame.index == 1) then
		height = height + WATCHFRAME_TYPE_OFFSET;
		scrollEnd = scrollEnd - WATCHFRAME_TYPE_OFFSET;
	end
	
	frame.totalTime = frame.totalTime+timestep;
	if (frame.totalTime > frame.slideInTime) then
		frame.totalTime = frame.slideInTime;
	end
	
	local scrollPos = scrollEnd;
	if (frame.slideInTime and frame.slideInTime > 0) then
		height = height*(frame.totalTime/frame.slideInTime);
		scrollPos = scrollStart + (scrollEnd-scrollStart)*(frame.totalTime/frame.slideInTime);
	end
	frame:SetHeight(height);
	frame:UpdateScrollChildRect();
	frame:SetVerticalScroll(floor(scrollPos+0.5));
	
	if (frame.totalTime >= frame.slideInTime) then
		frame:SetScript("OnUpdate", nil);
		WatchFrame_Update();
		frame.ScrollChild.Shine:Show();
		frame.ScrollChild.IconShine:Show();
		frame.ScrollChild.Shine.Flash:Play();
		frame.ScrollChild.IconShine.Flash:Play();
	end
end

function WatchFrameAutoQuest_SlideIn(frame, slideInTime)
	frame.totalTime = 0;
	frame.slideInTime = slideInTime;
	frame:SetHeight(1);
	frame:SetScript("OnUpdate", WatchFrameAutoQuest_OnUpdate);
end

function WatchFrameAutoQuest_AddPopUp(questID, type)
	if (AddAutoQuestPopUp(questID, type)) then
		WatchFrame_Update(WatchFrame);
		WatchFrame_Expand(WatchFrame);
		return true;
	end
	return false;
end

function WatchFrameAutoQuest_ClearPopUp(questID)
	RemoveAutoQuestPopUp(questID);
	WatchFrame_Update(WatchFrame);
end

function WatchFrameAutoQuest_ClearPopUpByLogIndex(questIndex)
	local questID = select(9, GetQuestLogTitle(questIndex));
	WatchFrameAutoQuest_ClearPopUp(questID);
end