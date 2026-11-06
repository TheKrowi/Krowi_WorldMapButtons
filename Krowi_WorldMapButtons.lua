--[[
    Copyright (c) 2020 Krowi
    Licensed under the terms of the LICENSE file in this repository.
]]

---@diagnostic disable: undefined-global

local lib, oldminor = LibStub:NewLibrary('Krowi_WorldMapButtons-1.4', 12);

if not lib then
	return;
end

local version = (GetBuildInfo());
local major = string.match(version, "(%d+)%.(%d+)%.(%d+)(%w?)");
major = tonumber(major);
-- WoW Forever reports a 1.x build but ships the retail world map
lib.IsForever = major <= 3 and WorldMapTrackingPinButtonMixin ~= nil;
lib.HasNoOverlay = major <= 3 and not lib.IsForever;
lib.IsMainline = major >= 11 or lib.IsForever;

-- Forever owns the top-left map pin button; addon buttons stack below its reserved slot
if lib.IsForever then
	lib.AnchorPoint, lib.XOffset, lib.YOffset = "TOPLEFT", 3, -32;
else
	lib.AnchorPoint, lib.XOffset, lib.YOffset = "TOPRIGHT", 4, -2;
end

function lib:SetOffsets(xOffset, yOffset)
	self.XOffset = xOffset or self.XOffset;
	self.YOffset = yOffset or self.YOffset;
end

local function SetButtonPoint(button, xOffset, yOffset)
	button:ClearAllPoints();
	button:SetPoint(lib.AnchorPoint, button.relativeFrame, lib.AnchorPoint == "TOPLEFT" and xOffset or -xOffset, yOffset);
end

function lib.SetPoints()
	local xOffset, yOffset = lib.XOffset, lib.YOffset;
	for _, button in next, lib.Buttons do
		if button:IsShown() then
			SetButtonPoint(button, xOffset, yOffset);
			if lib.IsMainline then
				yOffset = yOffset - 32;
			else
				xOffset = xOffset + 32;
			end
		end
	end
end

local function IsTrackingOptionsButton(f)
	return WorldMapTrackingOptionsButtonMixin and f.OnLoad == WorldMapTrackingOptionsButtonMixin.OnLoad;
end

local function HookDefaultButtons()
	if WorldMapFrame.overlayFrames == nil then
		lib.HookedDefaultButtons = true;
		return;
	end

	for _, f in next, WorldMapFrame.overlayFrames do
		-- Forever keeps the tracking options button next to the nav bar
		if not lib.IsForever and IsTrackingOptionsButton(f) then
			tinsert(lib.Buttons, f);
		end
		if not lib.IsForever and WorldMapTrackingPinButtonMixin and f.OnLoad == WorldMapTrackingPinButtonMixin.OnLoad then
			tinsert(lib.Buttons, f);
		end
	end

	lib.HookedDefaultButtons = true;
end

local function AddButton(button)
	local xOffset, yOffset = lib.XOffset, lib.YOffset;
	if lib.IsMainline then
		yOffset = yOffset - #lib.Buttons * 32;
	else
		xOffset = xOffset + #lib.Buttons * 32;
	end
	button.relativeFrame = WorldMapFrame:GetCanvasContainer();
	SetButtonPoint(button, xOffset, yOffset);
	hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
		button:Refresh();
		lib.SetPoints();
	end);

	tinsert(lib.Buttons, button);

	return button;
end

function lib:Add(templateName, templateType)
	if self.Buttons == nil then
		self.Buttons = {};
	end

	if not self.HookedDefaultButtons then
		HookDefaultButtons();
	end

	local button = CreateFrame(templateType, "Krowi_WorldMapButtons" .. (#self.Buttons + 1), lib.HasNoOverlay and WorldMapFrame.ScrollContainer or WorldMapFrame, templateName);

	if lib.HasNoOverlay then
		button:SetFrameStrata("TOOLTIP");
	end

	return AddButton(button);
end

-- handle upgrades

if oldminor and oldminor == 1 then
	lib.Buttons = lib.buttons;
end

if oldminor and oldminor == 3 then
	if lib.HasNoOverlay then
		for _, button in next, lib.Buttons do
			button:SetParent(WorldMapFrame.ScrollContainer);
			button:SetFrameStrata("TOOLTIP");
		end
	end
end

-- Older minors adopted Blizzard buttons on Forever; leave their layout to the client
if oldminor and oldminor < 12 and lib.IsForever and lib.Buttons then
	for i = #lib.Buttons, 1, -1 do
		local button = lib.Buttons[i];
		if IsTrackingOptionsButton(button) or (WorldMapTrackingPinButtonMixin and button.OnLoad == WorldMapTrackingPinButtonMixin.OnLoad) then
			tremove(lib.Buttons, i);
		elseif button:GetParent() == WorldMapFrame.ScrollContainer then
			button:SetParent(WorldMapFrame);
			button:SetFrameStrata("HIGH"); -- same strata as Blizzard's map buttons
		end
	end
	lib.SetPoints();
end
