
function InspectPaperDollFrame_OnLoad(self)
	self:RegisterEvent("UNIT_MODEL_CHANGED");
	self:RegisterEvent("UNIT_LEVEL");
	self:RegisterEvent("INSPECT_READY");
	if(not C_PaperDollInfo.IsRangedSlotShown()) then
		InspectRangedSlot:Hide();
		InspectMainHandSlot:SetPoint("TOPLEFT", self:GetParent(), "BOTTOMLEFT", 132, 50);
	end
	if(ClassicExpansionAtLeast(LE_EXPANSION_MISTS_OF_PANDARIA)) then
		InspectModelFrameRotateRightButton:Hide();
		InspectModelFrameRotateLeftButton:Hide();
	end
end

function InspectPaperDollFrame_OnEvent(self, event, unit)
	if (InspectFrame:IsShown()) then
		if ( unit and unit == InspectFrame.unit ) then
			if ( event == "UNIT_MODEL_CHANGED" ) then
				InspectModelFrame:RefreshUnit();
			elseif ( event == "UNIT_LEVEL" ) then
				InspectPaperDollFrame_SetLevel();
			end
			return;
		end
		if (event == "INSPECT_READY" and InspectFrame.unit and (UnitGUID(InspectFrame.unit) == unit)) then
			InspectPaperDollFrame_SetLevel();
			InspectPaperDollFrame_UpdateButtons();
		end
	end
end

function InspectPaperDollFrame_UpdateButtons()
	InspectPaperDollItemSlotButton_Update(InspectHeadSlot);
	InspectPaperDollItemSlotButton_Update(InspectNeckSlot);
	InspectPaperDollItemSlotButton_Update(InspectShoulderSlot);
	InspectPaperDollItemSlotButton_Update(InspectBackSlot);
	InspectPaperDollItemSlotButton_Update(InspectChestSlot);
	InspectPaperDollItemSlotButton_Update(InspectShirtSlot);
	InspectPaperDollItemSlotButton_Update(InspectTabardSlot);
	InspectPaperDollItemSlotButton_Update(InspectWristSlot);
	InspectPaperDollItemSlotButton_Update(InspectHandsSlot);
	InspectPaperDollItemSlotButton_Update(InspectWaistSlot);
	InspectPaperDollItemSlotButton_Update(InspectLegsSlot);
	InspectPaperDollItemSlotButton_Update(InspectFeetSlot);
	InspectPaperDollItemSlotButton_Update(InspectFinger0Slot);
	InspectPaperDollItemSlotButton_Update(InspectFinger1Slot);
	InspectPaperDollItemSlotButton_Update(InspectTrinket0Slot);
	InspectPaperDollItemSlotButton_Update(InspectTrinket1Slot);
	InspectPaperDollItemSlotButton_Update(InspectMainHandSlot);
	InspectPaperDollItemSlotButton_Update(InspectSecondaryHandSlot);
	if(C_PaperDollInfo.IsRangedSlotShown()) then
		InspectPaperDollItemSlotButton_Update(InspectRangedSlot);
	end
end

local factionLogoTextures = {
	["Alliance"]	= "Interface\\Timer\\Alliance-Logo",
	["Horde"]		= "Interface\\Timer\\Horde-Logo",
	["Neutral"]		= "Interface\\Timer\\Panda-Logo",
};

function InspectPaperDollFrame_OnShow()
	InspectModelFrame:Show();
	local modelCanDraw = InspectModelFrame:SetUnit(InspectFrame.unit);
	InspectPaperDollFrame_SetLevel();
	InspectPaperDollFrame_UpdateButtons();
	
	-- If the paperdoll model is not available to draw (out of range), then draw the faction logo
	if(modelCanDraw ~= true) then
		local factionGroup = UnitFactionGroup(InspectFrame.unit);
		if ( factionGroup ) then
			InspectFaction:SetTexture(factionLogoTextures[factionGroup]);
			InspectFaction:Show();
			InspectModelFrame:Hide();
		else
			InspectFaction:Hide();
		end
	else
		InspectFaction:Hide();
	end
	if(ClassicExpansionAtLeast(LE_EXPANSION_CATACLYSM)) then
		SetPaperDollBackground(InspectModelFrame, InspectFrame.unit);
		InspectModelFrameBackgroundTopLeft:SetDesaturated(1);
		InspectModelFrameBackgroundTopRight:SetDesaturated(1);
		InspectModelFrameBackgroundBotLeft:SetDesaturated(1);
		InspectModelFrameBackgroundBotRight:SetDesaturated(1);
	end
end

function InspectPaperDollItemSlotButton_OnLoad(self)
	self:RegisterEvent("UNIT_INVENTORY_CHANGED");
	local slotName = self:GetName();
	if(not C_PaperDollInfo.IsRangedSlotShown() and slotName == "InspectRangedSlot") then
		return;
	end
	local id;
	local textureName;
	local checkRelic;
	id, textureName, checkRelic = GetInventorySlotInfo(strsub(slotName,8));
	self:SetID(id);
	local texture = _G[slotName.."IconTexture"];
	texture:SetTexture(textureName);
	self.backgroundTextureName = textureName;
	self.checkRelic = checkRelic;
end

function InspectPaperDollItemSlotButton_OnEvent(self, event, ...)
	if ( event == "UNIT_INVENTORY_CHANGED" ) then
		local unit = ...;
		if ( unit == InspectFrame.unit ) then
			InspectPaperDollItemSlotButton_Update(self);
		end
		return;
	end
end

function InspectPaperDollItemSlotButton_OnClick(self, button)
	HandleModifiedItemClick(GetInventoryItemLink(InspectFrame.unit, self:GetID()));
end

function InspectPaperDollItemSlotButton_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	if ( not GameTooltip:SetInventoryItem(InspectFrame.unit, self:GetID()) ) then
		local text = _G[strupper(strsub(self:GetName(), 8))];
		if ( self.checkRelic and UnitHasRelicSlot(InspectFrame.unit) ) then
			text = _G["RELICSLOT"];
		end
		GameTooltip:SetText(text);
	end
	CursorUpdate(self);
end

function InspectPaperDollItemSlotButton_Update(button)
	local unit = InspectFrame.unit;
	local textureName = GetInventoryItemTexture(unit, button:GetID());
	if ( textureName ) then
		SetItemButtonTexture(button, textureName);
		SetItemButtonCount(button, GetInventoryItemCount(unit, button:GetID()));
		button.hasItem = 1;
	else
		textureName = button.backgroundTextureName;
		if ( button.checkRelic and UnitHasRelicSlot(unit) ) then
			textureName = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Relic.blp";
		end
		SetItemButtonTexture(button, textureName);
		SetItemButtonCount(button, 0);
		button.IconBorder:Hide();
		button.hasItem = nil;
	end
	if ( GameTooltip:IsOwned(button) ) then
		GameTooltip:Hide();
	end
end
