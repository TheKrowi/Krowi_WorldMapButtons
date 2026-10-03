### Added (1.4.11)
- WoW Forever support: buttons stack downwards from the top-left corner of the map, below Blizzard's map pin button, and the tracking options button stays next to the nav bar

### Fixed (1.4.11)
- WoW Forever: the map pin button no longer stretches across the top of the map (hover glow and tooltip along the whole top edge), and the tracking options button is no longer pulled into the map
- WoW Forever: buttons created by an older embedded copy of the library are moved onto the world map frame with `HIGH` strata instead of `TOOLTIP`
- Buttons now clear their previous anchors before being positioned

### Changed (1.4.11)
- Removed the unused `KrowiWorldMapButtonsIndex` field that was written onto Blizzard's map buttons