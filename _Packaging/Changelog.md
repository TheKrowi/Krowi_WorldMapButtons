# Changelog
All notable changes to this project will be documented in this file.

## 1.4.11 - 2026-10-03
### Added
- WoW Forever support: buttons stack downwards from the top-left corner of the map, below Blizzard's map pin button, and the tracking options button stays next to the nav bar

### Fixed
- WoW Forever: the map pin button no longer stretches across the top of the map (hover glow and tooltip along the whole top edge), and the tracking options button is no longer pulled into the map
- WoW Forever: buttons created by an older embedded copy of the library are moved onto the world map frame with `HIGH` strata instead of `TOOLTIP`
- Buttons now clear their previous anchors before being positioned

### Changed
- Removed the unused `KrowiWorldMapButtonsIndex` field that was written onto Blizzard's map buttons

## 1.4.10 - 2026-06-06
### Fixed
- Taint fix: removed `PatchWrathClassic` patch, hook now always uses `OnMapChanged` (dev note: this is at least an attempt at fixing `Blizzard_SharedXML/LayoutFrame.lua:491: attempt to compare a secret number value`)

### Changed
- Files renamed to be in line with my other libraries

## 1.4.9 - 2025-12-08
### Changed
- Codebase for upload

## 1.4.8 - 2025-02-22
### Changed
- 11.1.0 map changes

## 1.4.6 - 2024-06-27
### Changed
- The War Within compatibility
- No longer compatible with Krowi_WorldMapButtons 1.3.1

## 1.4.5 - 2023-03-29
### Added
- Classic era and TBC classic support

## 1.4.4 - 2023-03-29
### Fixed
- Proper compatibility fix for Leatrix Maps with backwards compatibility

## 1.4 - 2023-03-29
### Added
- Wrath Classic compatibility

## 1.3 - 2023-03-29
### Added
- License