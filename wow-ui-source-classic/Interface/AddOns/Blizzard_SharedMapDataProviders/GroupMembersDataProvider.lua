GroupMembersDataProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin);

function GroupMembersDataProviderMixin:OnAdded(mapCanvas)
	MapCanvasDataProviderMixin.OnAdded(self, mapCanvas);

	-- a single permanent pin
	local pin = self:GetMap():AcquirePin("GroupMembersPinTemplate", self);
	pin:SetPosition(0.5, 0.5);
	pin:SetNeedsPeriodicUpdate(true);
	pin:UpdateShownUnits();
	self.pin = pin;
	self.onClickHandler = self.onClickHandler or function(mapCanvas, button, cursorX, cursorY) return self.pin:OnCanvasClicked(button, cursorX, cursorY) end;
	mapCanvas:AddCanvasClickHandler(self.onClickHandler);
end

function GroupMembersDataProviderMixin:OnRemoved(mapCanvas)
	MapCanvasDataProviderMixin.OnRemoved(self, mapCanvas);
	self:GetMap():RemoveAllPinsByTemplate("GroupMembersPinTemplate");
	mapCanvas:RemoveCanvasClickHandler(self.onClickHandler);
end

function GroupMembersDataProviderMixin:OnMapChanged()
	self.pin:OnMapChanged();
end

function GroupMembersDataProviderMixin:RefreshAllData(fromOnShow)
	self.pin:Refresh(fromOnShow);
end

function GroupMembersDataProviderMixin:SetUnitPinSize(unit, size)
	local unitPinSizes = self:GetUnitPinSizesTable();
	if unitPinSizes[unit] then
		unitPinSizes[unit] = size;
		if self.pin then
			self.pin:UpdateShownUnits();
			self.pin:SynchronizePinSizes();
		end
	end
end

function GroupMembersDataProviderMixin:EnumerateUnitPinSizes()
	local unitPinSizes = self:GetUnitPinSizesTable();
	return next, unitPinSizes;
end

function GroupMembersDataProviderMixin:ShouldShowUnit(unit)
	local unitPinSizes = self:GetUnitPinSizesTable();
	return unitPinSizes[unit] and unitPinSizes[unit] > 0;
end

function GroupMembersDataProviderMixin:GetUnitPinSizesTable()
	if not self.unitPinSizes then
		self.unitPinSizes = {
			player = 16,
			party = 16,
			raid = 16,
		};
	end
	return self.unitPinSizes;
end

--[[ Group Members Pin ]]--
GroupMembersPinMixin = CreateFromMixins(MapCanvasPinMixin);

function GroupMembersPinMixin:OnLoad()
	UnitPositionFrameMixin.OnLoad(self);
	self:SetAlphaLimits(1.0, 1.0, 1.0);
	self:SetIgnoreGlobalPinScale(true);
	self:UseFrameLevelType("PIN_FRAME_LEVEL_GROUP_MEMBER");

	self:SetPlayerPingTexture(Enum.PingTextureType.Center, "Interface\\minimap\\UI-Minimap-Ping-Center", 32, 32);
	self:SetPlayerPingTexture(Enum.PingTextureType.Expand, "Interface\\minimap\\UI-Minimap-Ping-Expand", 32, 32);
	self:SetPlayerPingTexture(Enum.PingTextureType.Rotation, "Interface\\minimap\\UI-Minimap-Ping-Rotate", 70, 70);

	self:SetMouseOverUnitExcluded("player", true);
	self:SetPinTexture("player", "Interface\\WorldMap\\WorldMapArrow");
end

function GroupMembersPinMixin:OnAcquired(dataProvider)
	self.dataProvider = dataProvider;
	self:SynchronizePinSizes();
end

function GroupMembersPinMixin:OnShow()
	UnitPositionFrameMixin.OnShow(self);
end

function GroupMembersPinMixin:OnHide()
	UnitPositionFrameMixin.OnHide(self);
	if self.dataProvider:ShouldShowUnit("player") then
		self:StopPlayerPing();
	end
	if GameTooltip:GetOwner() == self then
		GameTooltip:Hide();
	end
end

function GroupMembersPinMixin:OnUpdate()
	self:Refresh();
end

function GroupMembersPinMixin:Refresh(fromOnShow)
	self:UpdatePlayerPins();

	self:UpdateTooltips(GameTooltip);

	if fromOnShow then
		self:OnMapChanged();
	end
end

function GroupMembersPinMixin:OnMapChanged()
	local mapID = self:GetMap():GetMapID();
	local hideMapIcons = C_Map.GetMapDisplayInfo(mapID);
	if hideMapIcons then
		self:Hide();
	else
		self:SetUiMapID(mapID);
		self:Show();
		if self.dataProvider:ShouldShowUnit("player") then
			self:StartPlayerPing(2, .25);
		end
	end
end

function GroupMembersPinMixin:UpdateShownUnits()
	for unit, size in self.dataProvider:EnumerateUnitPinSizes() do
		self:SetShouldShowUnits(unit, size > 0 and not C_Commentator.IsSpectating());
	end
end

function GroupMembersPinMixin:SynchronizePinSizes()
	local scale = self:GetMap():GetCanvasScale();
	for unit, size in self.dataProvider:EnumerateUnitPinSizes() do
		if self.dataProvider:ShouldShowUnit(unit) then
			self:SetPinSize(unit, size / scale);
		end
	end
	self:SetPlayerPingScale(.35 / scale);
end

function GroupMembersPinMixin:OnCanvasSizeChanged()
	self:SetSize(self:GetMap():DenormalizeHorizontalSize(1.0), self:GetMap():DenormalizeVerticalSize(1.0));
	self:SynchronizePinSizes();
end

function GroupMembersPinMixin:OnCanvasScaleChanged()
	self:SynchronizePinSizes();
end

function GroupMembersPinMixin:OnCanvasClicked(button, cursorX, cursorY)
	self.reportableUnits = { };
	if GetCVarBool("enablePVPNotifyAFK") and button == "RightButton" then
		local _, instanceType = IsInInstance();
		if instanceType == "pvp" then
			local timeNowSeconds = GetTime();
			local mouseOverUnits = self:GetCurrentMouseOverUnits();
			for unit in pairs(mouseOverUnits) do
				if unit ~= "player" and not GetIsPVPInactive(unit, timeNowSeconds) then
					tinsert(self.reportableUnits, unit);
				end
			end
		end

		if #self.reportableUnits > 0 then
			MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
				rootDescription:SetTag("MENU_GROUP_MEMBERS_PIN");

				rootDescription:CreateTitle(PVP_REPORT_AFK);

				for i, unit in ipairs(self.reportableUnits) do
					rootDescription:CreateButton(UnitName(unit), function()
						ReportPlayerIsPVPAFK(unit);
					end);
				end

				if #self.reportableUnits > 1 then
					rootDescription:CreateButton(PVP_REPORT_AFK_ALL, function()
						for i, unit in ipairs(self.reportableUnits) do
							ReportPlayerIsPVPAFK(unit);
						end
					end);
				end

			end);
			return true;
		end
	end

	return false;
end