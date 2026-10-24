![Retail](https://img.shields.io/badge/Retail-12.1.5-008833?style=for-the-badge) ![Mists](https://img.shields.io/badge/Mists-5.5.4-28ae7e?style=for-the-badge) ![Titan](https://img.shields.io/badge/Titan-3.80.2-5d6d7e?style=for-the-badge) ![Forever](https://img.shields.io/badge/Forever-1.60.1-e6cc80?style=for-the-badge) ![Classic](https://img.shields.io/badge/Classic-1.15.9-c39361?style=for-the-badge)<br>
[![CurseForge](https://img.shields.io/badge/curseforge-download-F16436?style=for-the-badge&logo=curseforge&logoColor=white)](https://www.curseforge.com/wow/addons/krowi-world-map-buttons) [![Wago](https://img.shields.io/badge/Wago-Download-c1272d?style=for-the-badge)](https://addons.wago.io/addons/krowi-world-map-buttons)<br>
[![Discord](https://img.shields.io/badge/discord-join-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/mdBFQJYeQZ) [![PayPal](https://img.shields.io/badge/paypal-donate-002991.svg?style=for-the-badge&logo=paypal&logoColor=white)](https://www.paypal.com/donate/?hosted_button_id=9QEDV37APQ6YJ)

A library for World of Warcraft addon development that simplifies adding custom buttons to the world map interface with automatic positioning and dynamic layout management.

## Features

### World Map Button Library (`Krowi_WorldMapButtons-1.4`)
- **Easy Button Integration**: Add custom buttons to the world map with a single function call
- **Automatic Positioning**: Buttons line up in one row with Blizzard's own map buttons, in a top corner of the map
- **Dynamic Layout**: Hidden buttons leave no gap in the row
- **Multi-Version Support**: Works on Retail, Mists of Pandaria Classic, WoW Forever and the 1.x to 3.x Classic clients (Classic Era, Anniversary, Titan Reforged)
- **Default Button Integration**: Blizzard's map buttons (on Retail the tracking options and map pin buttons) take the first places in the row
- **Independent**: No dependency on other addons for world map modifications
- **LibStub Support**: Standard LibStub library structure for dependency management

## Usage Examples

### Basic Button Setup
```lua
local WorldMapButtons = LibStub("Krowi_WorldMapButtons-1.4")

-- Your template's mixin must have a Refresh method, see below
local button = WorldMapButtons:Add("YourAddon_WorldMapButton_Template", "BUTTON")
```

### Button Mixin Example
Only `Refresh` is required by the library. The other methods are the scripts of the sample template.
```lua
YourAddon_WorldMapButtonMixin = {}

function YourAddon_WorldMapButtonMixin:OnLoad()
    -- Initialize your button
end

function YourAddon_WorldMapButtonMixin:OnMouseDown(button)
    -- Handle mouse down event
end

function YourAddon_WorldMapButtonMixin:OnMouseUp()
    -- Handle mouse up event
end

function YourAddon_WorldMapButtonMixin:OnClick()
    -- Handle click event
end

function YourAddon_WorldMapButtonMixin:OnEnter()
    -- Show tooltip or highlight
end

function YourAddon_WorldMapButtonMixin:OnHide()
    -- Clean up when hidden
end

function YourAddon_WorldMapButtonMixin:Refresh()
    -- Required: called after every map change, before the row is laid out again
    -- Use this to update button state:
    -- self:Enable(), self:Disable(), self:Show(), self:Hide()
end
```

### Button Template Example (XML)
See [ButtonTemplate.xml](https://github.com/TheKrowi/Krowi_WorldMapButtons/blob/main/_Packaging/ButtonTemplate.xml) for a complete example template.

### Button Without a Template
```lua
local button = WorldMapButtons:Add(nil, "BUTTON")
button:SetSize(32, 32)
function button:Refresh()
end
```

### Showing or Hiding Your Button
```lua
-- Outside a map change, lay the row out again yourself so no gap is left
button:SetShown(showButton)
WorldMapButtons.SetPoints()
```

### Custom Offset Configuration
```lua
local WorldMapButtons = LibStub("Krowi_WorldMapButtons-1.4")

-- Moves the start of the whole row, so every addon's buttons move with it
WorldMapButtons:SetOffsets(8, -4)  -- xOffset, yOffset
```
Loading a newer copy of the library resets the offsets, so set them once all addons have loaded (`PLAYER_LOGIN` or later). They apply from the next map change or `SetPoints()` call.

## API Reference

### Library Functions

| Function | Parameters | Returns | Description |
|----------|------------|---------|-------------|
| `Add(templateName, templateType)` | `templateName` (string or nil), `templateType` (string) | frame | Creates a button from the template, places it at the end of the row and returns it |
| `SetOffsets(xOffset, yOffset)` | `xOffset` (number, optional), `yOffset` (number, optional) | - | Moves the start of the row. Defaults: xOffset=4, yOffset=-2 (WoW Forever: 3, 0) |
| `SetPoints()` | - | - | Lays the row out again. Call it as `WorldMapButtons.SetPoints()` after showing or hiding your button outside a map change |

### Add() Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `templateName` | string | No | The name of your button template defined in XML. With nil the button is created bare and you build it in code |
| `templateType` | string | Yes | The frame type, typically "BUTTON"; "DropdownButton" works on clients that have it |

**Returns:** The created button, named `Krowi_WorldMapButtons<n>`. Its parent is `WorldMapFrame`, or on Classic Era, Anniversary and Titan Reforged `WorldMapFrame.ScrollContainer` with `TOOLTIP` strata.

### Button Methods
The library calls one method on your button:

| Method | Parameters | Description |
|--------|------------|-------------|
| `Refresh()` | - | Required. Called after every map change, before the row is laid out again. Update button state here |

`Refresh` runs inside Blizzard's map update, so keep it free of errors.

### Library Properties

| Property | Type | Description |
|----------|------|-------------|
| `IsMainline` | boolean | True on Retail (11.x and later) and WoW Forever; buttons stack downwards |
| `IsForever` | boolean | True on WoW Forever |
| `HasNoOverlay` | boolean | True on Classic Era, Anniversary and Titan Reforged; buttons are parented to `WorldMapFrame.ScrollContainer` |
| `AnchorPoint` | string | The corner the row starts in: "TOPRIGHT", or "TOPLEFT" on WoW Forever |
| `XOffset` | number | Horizontal offset for the start of the row (default: 4; WoW Forever: 3) |
| `YOffset` | number | Vertical offset for the start of the row (default: -2; WoW Forever: 0) |
| `Buttons` | table | Array of all buttons in the row, in order, Blizzard's first |

## Positioning Behavior

### Retail
- Buttons are stacked **vertically** from top to bottom
- Position: Top-right corner of the map, below Blizzard's tracking options and map pin buttons
- Each button is 32 pixels below the previous one

### WoW Forever
- Buttons are stacked **vertically** from top to bottom
- Position: Top-left corner of the map, below Blizzard's map pin button
- Each button is 32 pixels below the previous one
- The tracking options button stays where Blizzard puts it, next to the nav bar

### Mists of Pandaria Classic, Classic Era, Anniversary and Titan Reforged
- Buttons are arranged **horizontally** from right to left
- Position: Top-right corner of the map
- Each button is 32 pixels to the left of the previous one

### Dynamic Layout
- After every map change, and whenever `SetPoints()` is called, the shown buttons close up so a hidden button leaves no gap
- Buttons keep the order in which they were added, after Blizzard's buttons

## Technical Details

### Version Detection
The library reads the major version from `GetBuildInfo()`:
- **11 and later**: Retail
- **5**: Mists of Pandaria Classic
- **1 to 3, with `WorldMapTrackingPinButtonMixin`**: WoW Forever, which runs Retail's world map
- **1 to 3, without it**: Classic Era, Anniversary and Titan Reforged

### Refresh Hook
Each button hooks `WorldMapFrame.OnMapChanged` on every client. The hook calls the button's `Refresh()` and then `SetPoints()`.

Blizzard calls `OnMapChanged` only when the map shows a different map than before:
- Opening the world map for the first time, or on another map than it was closed on
- Switching between different maps
- Changing continents or zones

Zooming does not call it, and neither does reopening the map on the map it was closed on.

## Use Cases
- Quick access to addon features from the world map
- Toggle visibility of custom map overlays or pins
- Open addon configuration panels
- Display addon-specific information
- Navigate to addon-related content
- Filter or search map data
- Any functionality requiring map-context interaction

## Requirements
- LibStub

## License
BSD 3-clause, see [LICENSE](https://github.com/TheKrowi/Krowi_WorldMapButtons/blob/main/LICENSE). It covers every 1.4 release, including those before 1.4.12.