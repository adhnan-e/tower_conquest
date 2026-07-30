# Tower Conquest: Planning & Design Documentation

This folder contains all the planning, design, and orchestration documentation for the Tower Conquest game project.

## Folder Structure

### `01_design/`
**Game Design Document (GDD):** The complete vision, core gameplay loop, mechanics, and production roadmap for Tower Conquest.

### `02_systems/`
**Gameplay Systems & Balance:** Detailed balance spreadsheets, building stats, unit stats, combat resolution math, and tuning guidelines.

### `03_assets/`
**Asset Catalog & Production Roadmap:** Complete list of all 200+ assets needed for the game, organized by type (buildings, units, effects, UI), with production phases and specifications.

### `04_implementation/`
**Flutter & Flame Implementation Guide:** Architecture overview, project structure, core Flame concepts, and code examples for runtime color tinting.

### `05_levels/`
**Level Design & Pacing:** Campaign structure, level-by-level design, and JSON data format for level definitions.

## Quick Start

1. **Read First:** Start with `01_design/01_GAME_DESIGN_DOCUMENT.md` to understand the overall vision and mechanics.
2. **Understand Balance:** Review `02_systems/01_GAMEPLAY_SYSTEMS_BALANCE.md` to see how the game is balanced.
3. **Asset Planning:** Check `03_assets/01_ASSET_CATALOG_PRODUCTION.md` to see what assets are needed and in what order.
4. **Implementation:** Use `04_implementation/01_FLUTTER_FLAME_GUIDE.md` as your development reference.
5. **Level Design:** Reference `05_levels/01_LEVEL_DESIGN.md` for campaign structure and level progression.

## Development Workflow

The **04_implementation/02_DEVELOPMENT_PROMPT.md** file contains a ready-to-use prompt for AI coding assistants. Copy and paste it into Cursor, ChatGPT, or your preferred AI tool to begin implementation.

## Key Design Principles

**Runtime Color Tinting:** All sprites are grayscale and tinted at runtime using Flame's `Paint` system with `ColorFilter.mode()` and `BlendMode.multiply`. This reduces asset count by 65% while enabling unlimited faction colors and cosmetic skins.

**Modular Architecture:** The game is built using Flame's component-based system. Each building, unit, and effect is a reusable component.

**Balanced Progression:** Levels are designed to teach mechanics implicitly, escalate difficulty smoothly, and reward strategic thinking.

## Asset Generation

**Do not generate assets until explicitly instructed.** The asset catalog defines all needed assets, but generation will happen in phases:

- **Phase 1 (MVP):** 52 core assets for a playable prototype.
- **Phase 2 (Expansion):** 92 assets for advanced mechanics.
- **Phase 3 (Polish):** 75 assets for tier progression.
- **Phase 4 (Content):** 60 cosmetic and event assets.

## Orchestration Model

This project uses a **producer-developer split model:**

- **Orchestrator (Manus AI):** Defines gameplay systems, maintains the asset pipeline, and structures content.
- **Developer (You):** Implements the codebase in Flutter/Flame, handles architecture, and optimizes performance.

This separation ensures clean design, scalable workflows, and maintainable code.

## Next Steps

1. Review the Game Design Document to understand the vision.
2. Set up your Flutter project with the directory structure outlined in the Implementation Guide.
3. Use the Development Prompt to bootstrap your codebase.
4. Implement Milestone 1 (MVP) with basic building spawning and unit movement.
5. Iterate on gameplay mechanics and balance.

---

**Last Updated:** July 2026  
**Version:** 1.0 (Planning Phase)
