# CLAUDE.md

Krowi's World Map Buttons (`Krowi_WorldMapButtons-1.4`) is a World of Warcraft LibStub library in Lua 5.1 that adds addon buttons to the world map in one row with Blizzard's own map buttons, and lays the row out again when the map changes. Krowi_AchievementFilter embeds it as a `Libs/Krowi_WorldMapButtons` git submodule, and many other authors' addons embed their own copies. The workspace-wide rules (tooling traps, the game loop, taint, git, release safety) load from `../../CLAUDE.md` and `Krowi_ClaudeKit/WowAddons.md`; this file adds only what is specific to this repo.

There is no build, lint or test step: the game, through a consumer, is the test harness. The `krowi` plugin (enabled in `.claude/settings.json`) syntax-checks every edited `.lua` with Lua 5.1 and guards the known tooling traps. The repo is public, but `.claude/settings.json` points at the private kit by absolute path, so the plugin loads only on Krowi's machine; that is intended.

## Clients and loading

- One TOC, `Krowi_WorldMapButtons.toc`: `## Interface: 120100, 50504, 11509, 16001, 38002` (Retail 12.1.0, Mists 5.5.4, Era 1.15.9, WoW Forever 1.60.1, Titan 3.80.2; not Anniversary). It counts only for a standalone install, the README badges and the upload game versions.
- All code is in `Krowi_WorldMapButtons.lua`; the TOC loads `Krowi_WorldMapButtons.xml`, which only loads that file. `_Packaging/ButtonTemplate.xml` is a sample template for consumers and is never loaded. LibStub is not bundled: an embedding addon provides it.
- The client comes from the major version of `GetBuildInfo()` and whether `WorldMapTrackingPinButtonMixin` exists (`:14-27`):

| Client | Flags | Button parent | Row |
|---|---|---|---|
| Retail (major 11 and up) | `IsMainline` | `WorldMapFrame` | down from the canvas's top right (4, -2) in 32 px steps, after Blizzard's tracking options and map pin buttons |
| Forever (major up to 3, pin mixin present) | `IsForever`, `IsMainline` | `WorldMapFrame` | down from the top left (3, 0), after the map pin button; the tracking options button is left alone |
| Mists (major 5) | none | `WorldMapFrame` | leftwards from the top right (4, -2) |
| Era, Anniversary, Titan (major up to 3) | `HasNoOverlay` | `WorldMapFrame.ScrollContainer`, `TOOLTIP` strata | leftwards from the top right |

- `HookDefaultButtons` (`:57-74`) runs on the first `Add` and adopts Blizzard's buttons from `WorldMapFrame.overlayFrames` by comparing their `OnLoad` with the Blizzard mixins'. The Era and Anniversary maps have no overlay frames.

## Versioning

- `Krowi_WorldMapButtons.lua:8` `LibStub:NewLibrary('Krowi_WorldMapButtons-1.4', 11)`; there is no other registration and no XML template.
- Copies at many minors load in any order. On Krowi's own clients (2026-10-17): Retail HandyNotes_* at minors 9 and 10 and RareScanner at 11; Classic Atlas, HandyNotes_BurningCrusade and HandyNotes_WrathOfTheLichKing at 5, RareScanner at 10 and a stale Krowi_Reminders deploy at 3; Forever RareScanner at 11. The newest copy's functions win, but the `lib` table survives and so does everything an older copy did before the upgrade: `lib.Buttons`, `lib.HookedDefaultButtons`, frames, and hooks from an `Add` that ran first (`OnMapChanged`, or `RefreshOverlayFrames` up to minor 9). Migrate that state in the `oldminor` handlers at the end of the file (`:113-139`).
- Loading a newer copy resets `AnchorPoint`, `XOffset` and `YOffset` (`:23-27`), dropping an earlier `SetOffsets`.
- Never change the major `-1.4`: a 1.5 was released and withdrawn (Krowi_AchievementFilter's changelog: "1.5 does no longer exist"). A new major name is a separate library next to the old one.

## Consumers

- Krowi_AchievementFilter (`Libs/Krowi_WorldMapButtons`, at 1.4.11): `LibStub("Krowi_WorldMapButtons-1.4"):Add("KrowiAF_WorldMapButton_Template", "BUTTON")` (`Gui/WorldMapButton/WorldMapButton.lua:22`), after which it keeps its button one strata above the Classic map with its own `hooksecurefunc(WorldMapFrame, "SetFrameStrata", ...)`; `.SetPoints()` when its show option changes (`Options/General.lua:89`). Its headless `worldmap` suite loads this file from `Libs/` against a model of the Mists map (`.claude/tools/headless/run-tests.lua:745`). A change ships by releasing the library and bumping that submodule.
- Other authors' addons rely on the API as it is: `Add` with a nil template (AllTheThings `"BUTTON"`, HandyNotes_WarWithin `"DropdownButton"`), the frame types `DROPDOWNBUTTON` (RareScanner) and `DROPDOWNTOGGLEBUTTON` (HandyNotes_*), `.SetPoints()` with a dot, `SetOffsets(40, 0)` (Leatrix Maps on Classic), and RareScanner on Classic, which sets `lib.HasNoOverlay = true` before its `Add` and writes `button.relativeFrame` itself. Keep these working.
- Questie (`Libs/Krowi_WorldMapButtons` at minor 10 in v12.1.0, 2026-10-12; `Questie_Camelot.toc` for Forever) calls `Add("QuestieWorldMapButtonTemplate", "BUTTON")` from `WorldMapButton.Initialize` after login (`Modules/WorldMapButton/WorldMapButton.lua`). On Forever it sets `lib.HasNoOverlay = false` at file load and, right after its `Add`, removes Blizzard's map pin and tracking options buttons from `lib.Buttons` (`ReleaseBlizzardMapButtons`, a workaround for 1.4.10). When a 1.4.11 copy wins (RareScanner's), the next map change puts the first addon button on the pin's spot (3, 0), under the pin (maqjav's report, 2026-10-23). Krowi chose to have Questie guard it with `not lib.IsForever` instead of defending against it in the library (2026-10-23).
- Krowi_Reminders calls `.SetPoints()` (`Options/General.lua:83`) but no longer embeds the library.

## Architecture and API

- `lib:Add(templateName, templateType)` (`:95`) creates `Krowi_WorldMapButtons<n>` (n counts every button in the row, Blizzard's included), sets `button.relativeFrame` to `WorldMapFrame:GetCanvasContainer()` (`:83`), places it and appends it to `lib.Buttons`.
- Each `Add` installs its own `hooksecurefunc(WorldMapFrame, "OnMapChanged", ...)` that calls `button:Refresh()` and then `lib.SetPoints()` (`:85-88`), so every button needs a `Refresh` method (AllTheThings adds an empty one).
- `lib.SetPoints()` (`:39`, called with a dot) walks `lib.Buttons` in order and anchors each shown button with `ClearAllPoints` and `SetPoint(AnchorPoint, button.relativeFrame, x, y)` (`:34-37`), so a hidden button leaves no gap.
- `lib:SetOffsets(x, y)` (`:29`) moves the start of the row. Public fields: `Buttons`, `HasNoOverlay`, `IsMainline`, `IsForever`, `AnchorPoint`, `XOffset`, `YOffset`.
- No saved variables, no events, no localized strings.

## Taint-sensitive areas

Everything here touches `WorldMapFrame`. Run the `krowi:taint-reviewer` agent after any code change.

- Buttons are children of `WorldMapFrame` or its `ScrollContainer` (`:104`), forced to `TOOLTIP` strata there (`:106-108`), and reparented by the upgrade handlers (`:119-139`).
- One `hooksecurefunc(WorldMapFrame, "OnMapChanged", ...)` per button (`:85`) runs the consumers' `Refresh` after Blizzard's map change, inside Blizzard's map `OnShow` and `SetMapID`, unprotected: a consumer's `Refresh` that errors (a secret compare in restricted content, say) may abort the rest of Blizzard's `OnShow`. The baseline review (2026-10-17) rates that plausible, not confirmed; `securecallfunction(button.Refresh, button)` would isolate the error, though not launder taint.
- `SetPoints` calls `ClearAllPoints` and `SetPoint` on Blizzard's own buttons in `lib.Buttons` after every map change: Retail's tracking options and map pin buttons, Forever's map pin button, Mists' zone timer.
- It reads `WorldMapFrame.overlayFrames` and their `OnLoad` (`:53-71`). Since 1.4.11 it writes no field onto Blizzard frames (`KrowiWorldMapButtonsIndex` removed). 1.4.10 removed the `RefreshOverlayFrames` hook and the `WorldMapFrame.RefreshOverlayFrames` stub (`PatchWrathClassic`) while chasing `LayoutFrame.lua:491: attempt to compare a secret number value` on Retail 12.x.

## Code style

Match the file you are editing:

- Tabs; statements end with `;`; double quotes, except the single-quoted name in the `NewLibrary` line.
- The `.lua` opens with the four-line `--[[ Copyright (c) 2020 Krowi ... ]]` block, a blank line, `---@diagnostic disable: undefined-global`, a blank line, then `NewLibrary` and its early return. The XML and the TOC carry the same notice as comments.
- CRLF on disk (LF in git, `core.autocrlf=true`), no BOM. `Krowi_WorldMapButtons.lua` ends with a newline, the other files do not. No `.editorconfig`; the tracked `.vscode/settings.json` only configures the Lua language server (Lua 5.1, the Ketho WoW API annotations) and has no fsdeploy.

## Testing in game

Test through Krowi_AchievementFilter, not with `Deploy.ps1` from this repo: that installs a second copy (`AddOns\Krowi_WorldMapButtons`) that counts only with a higher minor than every other copy in the AddOns folder.

1. Commit the change on this repo's branch.
2. In a Krowi_AchievementFilter worktree (`New-Worktree.ps1`), point the submodule at it: `git -C Libs\Krowi_WorldMapButtons fetch "E:\World of Warcraft Addon Development\Krowi_Libraries\Krowi_WorldMapButtons" <branch>`, then `git -C Libs\Krowi_WorldMapButtons checkout FETCH_HEAD`.
3. Run its headless suite: `& "E:\World of Warcraft Addon Development\Krowi_ClaudeKit\tools\lua51\lua.exe" ".claude\tools\headless\run-tests.lua" "$PWD" worldmap`.
4. Deploy that worktree (Retail, then `-Client Classic`), ask Krowi to `/reload`, open the map, switch maps, maximize and minimize it, toggle Krowi_AchievementFilter's world map button option, then run `Read-GameErrors.ps1` from it. Other addons' copies are installed too, so check that the new minor is the one loaded: `/dump LibStub.minors["Krowi_WorldMapButtons-1.4"]`.
5. Put the submodule pointer back before anything is committed there; the bump goes into Krowi_AchievementFilter's own PR after the release.

No Krowi addon loads the library on Forever or Era: only RareScanner (minor 11) is installed on `_classic_beta_`, and Era has no consumer installed.

## Git and release

- `main` is the only branch and the release branch: the `Release 1.4.9` and `Release 1.4.10` commits and every tag are on it. Branch from `main` and open PRs against it.
- 1.4.11 has no `Release` commit: its release notes and README were committed with the code in "Forever compatibility" (`b3e462d`), so the addon manager's commit step found nothing to commit (`Krowi_AddonManager_Python/git_helper.py:34-44`) and went on to the tag (annotated "Release 1.4.11", 20 seconds later) and the uploads (GitHub asset `Krowi_WorldMapButtons-v1.4.11.zip`).
- Release only with the plugin's `krowi:release` skill, from `E:\World of Warcraft Addon Development\Krowi_Libraries\Krowi_WorldMapButtons` (the library is in the addon manager's `LIBRARY_NAMES`). Every GitHub release so far is a full release: `--stability stable`. Do not prepare `README.md` or `_Packaging/ReleaseNotes.md` by hand.
- The addon manager writes `README.md` (badges from the TOC's `## Interface:` plus `_Packaging/Description.md`) and `_Packaging/ReleaseNotes.md` (only the newest changelog entry, with the version added to each heading). Edit `_Packaging/Description.md` and `_Packaging/Changelog.md`.
- The changelog's readers are addon authors: entries name the API and the frames they touch.
- After a release, bump `Libs/Krowi_WorldMapButtons` in Krowi_AchievementFilter.

## Known debt (verified 2026-10-17)

- Mists adopts Blizzard's zone timer into the row. In the Classic FrameXML `WorldMapTrackingOptionsButtonMixin` has no `OnLoad` (`Blizzard_WorldMap/Blizzard_WorldMapTemplates.lua:43`), so `IsTrackingOptionsButton` (`:53-55`) is true for every overlay frame without one, including the zone timer (`WorldMapZoneTimerMixin`, always shown, normally at the bottom of the map). `SetPoints` then moves it to the top right and pushes the addon buttons one slot left. Krowi_AchievementFilter's spec (`docs/work/2026-10-02-classic-world-map-button/spec.md:22`) says the floor dropdown is adopted too, but by the source it gets an `OnLoad` from `WowStyle1DropdownMixin` (`Blizzard_Menu/MenuTemplates.lua:764`); confirm in game.
- `_Packaging/Description.md`, and so `README.md`, is out of date. Its "Refresh Hook" section says Retail hooks `WorldMapFrame.RefreshOverlayFrames`; the code hooks `OnMapChanged` on every client since 1.4.10. It also places buttons only at the top right with defaults 4, -2 (Forever: top left, 3, 0), gives "Classic variants (Wrath, Classic, TBC)" the `ScrollContainer` parent and a horizontal row (Mists uses `WorldMapFrame`, Forever stacks downwards), and omits `IsForever` and `AnchorPoint`.
- `## Interface:` Retail 120100 lags 12.1.5 (120105).
- The row is laid out only on `OnMapChanged` (and an explicit `.SetPoints()`), so a button shown or hidden in between leaves a gap, or overlaps a neighbour when it comes back. Questie's `WorldMapButton.Toggle` and RareScanner's `RSMap.ToggleWorldmapButton` do not call `.SetPoints()`; Krowi_AchievementFilter does. On Forever, Blizzard's gamepad mode hides and shows the map pin (`Blizzard_WorldMap.lua:1268-1299`). maqjav proposed laying the row out again on show/hide; Krowi deferred it (2026-10-23). A fix would hook `Show`, `Hide` and `SetShown` on the library's own buttons, never on Blizzard's.