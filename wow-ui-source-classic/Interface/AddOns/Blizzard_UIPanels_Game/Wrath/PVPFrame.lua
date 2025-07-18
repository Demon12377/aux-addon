function PVPFrame_ExpansionSpecificOnLoad(self)
	self:RegisterEvent("BATTLEFIELDS_SHOW");
end

function PVPFrame_OnShow()
	if ( not GetCurrentArenaSeasonUsesTeams() ) then
		RequestRatedInfo();
	end
	PVPFrame_SetFaction();
	PVPFrame_Update();
	UpdateMicroButtons();
	SetPortraitTexture(PVPFramePortrait, "player");
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN);
end

function PVPFrame_OnHide()
	PVPTeamDetails:Hide();
	UpdateMicroButtons();
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE);
end

function PVPFrame_ExpansionSpecificOnEvent(self, event, ...)
	if ( event == "BATTLEFIELDS_SHOW" and not IsBattlefieldArena() ) then
		ShowUIPanel(PVPParentFrame);
		PVPParentFrameTab2:Click();
		BattlefieldFrame_UpdatePanelInfo();
	end
end

function PVPFrame_UpdateTabs()
	local selectedTab = PanelTemplates_GetSelectedTab(PVPParentFrame)
	if (selectedTab == nil or selectedTab == 1) then
		PVPParentFrameTab1:Click();
	elseif (selectedTab == 2) then
		PVPParentFrameTab2:Click();
	end
end

-- PVP Honor Data
function PVPHonor_Update()
	local hk, cp, dk, contribution, rank, highestRank, rankName, rankNumber;

	-- Yesterday's values
	hk = GetPVPYesterdayStats();
	PVPHonorYesterdayKills:SetText(hk);

	-- Lifetime values
	hk =  GetPVPLifetimeStats();
	PVPHonorLifetimeKills:SetText(hk);

	local honorCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo(Constants.CurrencyConsts.CLASSIC_HONOR_CURRENCY_ID);
	PVPFrameHonorPoints:SetText(honorCurrencyInfo.quantity);

	local arenaCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo(Constants.CurrencyConsts.CLASSIC_ARENA_POINTS_CURRENCY_ID);
	PVPFrameArenaPoints:SetText(arenaCurrencyInfo.quantity)	
	
	-- Today's values
	hk = GetPVPSessionStats();
	PVPHonorTodayKills:SetText(hk);
end
