# Scooby PS4 game downloads

Build and stage from the sibling scooby-ps4 checkout with release.bat. Select a game, build/test and choose its version, then update this repository locally. Commit/push is a separate confirmed action. The Manager app update feed is independent.

Each game uses sprx/<version>/<hash>/ for immutable plugin releases, version.json for the current plugin pointer and downloads/<category>/ for editable resource downloads. catalog.json indexes games; downloads/catalog.json indexes each game's resources. An empty resource catalog offers no downloads. Reserved folders do not establish PS4 format support.

R6 starts at 1.0.2; RDR2, GTA5, Overwatch and Fortnite start at 1.0.0. A configured version without version.json is not an available binary. Never upload account.json, passwords or device IDs. Existing R6 files were migrated from menus without changing their release identity. New plugins still require console acceptance; local structural checks do not establish native game functionality.
