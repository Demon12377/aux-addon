
EncounterJournalDataProviderMixin = CreateFromMixins(CVarMapCanvasDataProviderMixin);
EncounterJournalDataProviderMixin:Init("showBosses");

function EncounterJournalDataProviderMixin:OnShow()
	CVarMapCanvasDataProviderMixin.OnShow(self);
	self:RegisterEvent("PORTRAITS_UPDATED");
end

function EncounterJournalDataProviderMixin:OnHide()
	CVarMapCanvasDataProviderMixin.OnHide(self);
	self:UnregisterEvent("PORTRAITS_UPDATED");
end

function EncounterJournalDataProviderMixin:OnEvent(event, ...)
	CVarMapCanvasDataProviderMixin.OnEvent(self, event, ...);
	if event == "PORTRAITS_UPDATED" then
		self:RefreshAllData();
	end
end

function EncounterJournalDataProviderMixin:RemoveAllData()
	self:GetMap():RemoveAllPinsByTemplate("EncounterJournalPinTemplate");
end

function EncounterJournalDataProviderMixin:RefreshAllData(fromOnShow)
	self:RemoveAllData();

	if not self:IsCVarSet() then
		return;
	end

	if CanShowEncounterJournal() then
		local mapEncounters = C_EncounterJournal.GetEncountersOnMap(self:GetMap():GetMapID());
		for index, mapEncounterInfo in ipairs(mapEncounters) do
			local bossPin = self:GetMap():AcquirePin("EncounterJournalPinTemplate", mapEncounterInfo.encounterID);
			bossPin:SetPosition(mapEncounterInfo.mapX, mapEncounterInfo.mapY);
		end
	end
end

--[[ Pin ]]--
EncounterJournalPinMixin = CreateFromMixins(MapCanvasPinMixin);

function EncounterJournalPinMixin:OnLoad()
	self:SetScalingLimits(1, 0.7, 1.3);
	self:UseFrameLevelType("PIN_FRAME_LEVEL_ENCOUNTER");
end

function EncounterJournalPinMixin:OnAcquired(encounterID)
	self.encounterID = encounterID;
	self:Refresh();
end

function EncounterJournalPinMixin:Refresh()
	local name, description, encounterID, rootSectionID, link, instanceID = EJ_GetEncounterInfo(self.encounterID);
	self.instanceID = instanceID;
	self.tooltipTitle = name;
	self.tooltipText = description;
	local displayInfo = select(4, EJ_GetCreatureInfo(1, self.encounterID));
	self.displayInfo = displayInfo;
	if displayInfo then
		SetPortraitTextureFromCreatureDisplayID(self.Background, displayInfo);
		self.Background:Show();
	else
		self.Background:Hide();
	end
end

function EncounterJournalPinMixin:OnMouseEnter()
	if self.tooltipTitle then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT");
		GameTooltip:SetText(self.tooltipTitle, 1, 1, 1);
		GameTooltip:AddLine(self.tooltipText, nil, nil, nil, true);
		GameTooltip:Show();
	end
end

function EncounterJournalPinMixin:OnMouseLeave()
	if GameTooltip:GetOwner() == self then
		GameTooltip:Hide();
	end
end

function EncounterJournalPinMixin:OnClick()
	EncounterJournal_LoadUI();
	EncounterJournal_OpenJournal(nil, self.instanceID, self.encounterID);
end
