# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A World of Warcraft LibStub library (`Krowi_WorldMapButtons-1.4`) that lets other addons add buttons to the top-right of the world map and keeps them laid out as buttons are shown/hidden. All logic lives in [Krowi_WorldMapButtons.lua](Krowi_WorldMapButtons.lua); the load chain is `.toc` → `.xml` → `.lua`.

There is no build, lint, or test tooling. Verification means loading the addon in the game clients listed in the TOC's `## Interface:` line (currently Retail 12.x, Mists 5.x, Classic Era 1.x) and opening/switching the world map. LibStub is not bundled; it must be provided by an embedding addon.

[_Packaging/ButtonTemplate.xml](_Packaging/ButtonTemplate.xml) is a sample template for consumers. The TOC does not load it.

## Architecture

**LibStub versioning / upgrades.** Many addons embed this library and LibStub keeps only the highest minor version. The minor number is the second argument to `LibStub:NewLibrary('Krowi_WorldMapButtons-1.4', <minor>)`, and it must be bumped on every code change or the change will not win over older embedded copies. The `lib` table survives an upgrade, so state like `lib.Buttons` and `lib.HookedDefaultButtons` carries over from older minors. Migrations for that state go in the `oldminor` handlers at the bottom of the file. Hooks installed by older copies can't be removed, so changing hook behavior only affects buttons added after the upgrade. A breaking API change would require a new major name (e.g. `-1.5`).

**Client detection** comes from the major version of `GetBuildInfo()`:
- `HasNoOverlay` (major ≤ 3): buttons are parented to `WorldMapFrame.ScrollContainer` and forced to `TOOLTIP` strata.
- `IsMainline` (major ≥ 11): buttons stack vertically (32px steps). Every other client lays them out horizontally, right to left.

**Layout.** `lib.Buttons` is one ordered list that also contains Blizzard's own tracking-options and tracking-pin buttons. `HookDefaultButtons` finds these in `WorldMapFrame.overlayFrames` by matching their `OnLoad` against the Blizzard mixins, and they take the first slots. `SetPoints()` repositions only the shown buttons, anchored to `WorldMapFrame:GetCanvasContainer()`.

**Refresh contract.** Each `lib:Add()` call `hooksecurefunc`s `WorldMapFrame.OnMapChanged` to call `button:Refresh()` and then `lib.SetPoints()`. The consumer's mixin must therefore implement `Refresh`.

**Taint.** 1.4.10 removed a hook on `RefreshOverlayFrames` and a function stub patched onto `WorldMapFrame`, an attempted fix for a "secret number value" taint error on Retail 12.x. Don't replace or add fields on Blizzard frames; use `hooksecurefunc` only. The README's "Refresh Hook" section still describes the old `RefreshOverlayFrames` behavior and is out of date.

## Conventions

- Files are named `Krowi_<Name>.toc/.xml/.lua` with no version suffix, to match the sibling Krowi libraries in `../`. Each file starts with the two-line copyright/LICENSE header.
- Lua style: tabs, statements end with `;`, and `---@diagnostic disable: undefined-global` silences the Lua language server about WoW globals.

## Release steps (as done in past release commits)

1. Bump `## Version` in the TOC and the LibStub minor in the `.lua`. Update `## Interface:` if client versions changed.
2. Add a dated entry to the top of [_Packaging/Changelog.md](_Packaging/Changelog.md) (`## x.y.z - YYYY-MM-DD`, then `### Added/Changed/Fixed`).
3. Replace the contents of [_Packaging/ReleaseNotes.md](_Packaging/ReleaseNotes.md) with only this release's notes, using headings like `### Fixed (x.y.z)`.
4. Update the client-version badges at the top of [README.md](README.md). Apart from those badges, README.md and [_Packaging/Description.md](_Packaging/Description.md) have identical content, so mirror any doc change in both.
