# Tower Conquest: Documentation File Manifest

## Complete Documentation Package

This package contains all planning, design, and orchestration documentation for the Tower Conquest game.

### Root Level
- **DEVELOPMENT_PROMPT.md** – Ready-to-use prompt for AI coding assistants (Cursor, ChatGPT, etc.)
- **FILE_MANIFEST.md** – This file

### planning/01_design/
- **01_GAME_DESIGN_DOCUMENT.md** (13 KB)
  - Executive summary
  - Project vision and orchestration model
  - Core gameplay loop (5 phases)
  - Game mechanics (buildings, units, combat)
  - Economy and progression systems
  - Level progression and content pacing
  - Visual design and art direction
  - UI/UX screen flow
  - Monetization and live ops
  - Technical architecture overview
  - Production milestones and roadmap
  - Success metrics

### planning/02_systems/
- **01_GAMEPLAY_SYSTEMS_BALANCE.md** (12 KB)
  - Building systems and balance (4 types, 5 tiers)
  - Unit systems and balance (3 classes)
  - Combat and capture resolution mechanics
  - Meta-progression and economy
  - Difficulty levels and AI behavior
  - Balance tuning variables
  - Special mechanics and advanced features
  - Balance testing checklist
  - Economy spreadsheet

### planning/03_assets/
- **01_ASSET_CATALOG_PRODUCTION.md** (18 KB)
  - Asset architecture overview (base/detail layer system)
  - Complete asset list (200+ assets)
    - Buildings (40 files)
    - Units (20 files)
    - Environment (30 files)
    - Effects (25 files)
    - UI Elements (50 files)
    - Progression & Cosmetics (30 files)
  - Production roadmap (4 phases)
  - Asset specifications and design guidelines
  - Asset naming convention
  - Asset integration checklist
  - Future asset expansion notes

### planning/04_implementation/
- **01_FLUTTER_FLAME_GUIDE.md** (16 KB)
  - Project setup and architecture
  - pubspec.yaml dependencies
  - Project directory structure
  - Core Flame concepts
  - Faction color management
  - Base Building component code
  - Base Unit component code
  - Asset paths manager
  - Main entry point
  - Performance optimization tips
  - Development workflow
  - Next steps

### planning/05_levels/
- **01_LEVEL_DESIGN.md** (6 KB)
  - Level design philosophy
  - Campaign 1: The Basics (Levels 1-5)
  - Campaign 2: Advanced Tactics (Levels 6-15)
  - Campaign 3: Environmental Hazards (Levels 16-30)
  - Map generation data structure (JSON format)

### planning/README.md
- Quick start guide
- Folder structure overview
- Development workflow
- Key design principles
- Asset generation phases
- Orchestration model explanation
- Next steps

---

## File Statistics

| Category | Files | Total Size |
| :--- | :--- | :--- |
| Design | 1 | 13 KB |
| Systems | 1 | 12 KB |
| Assets | 1 | 18 KB |
| Implementation | 1 | 16 KB |
| Levels | 1 | 6 KB |
| README & Manifest | 2 | 8 KB |
| **Total** | **7 MD files** | **~73 KB** |

## How to Use This Package

### For Project Setup
1. Read `planning/01_design/01_GAME_DESIGN_DOCUMENT.md` for the overall vision.
2. Use `planning/04_implementation/01_FLUTTER_FLAME_GUIDE.md` to set up your Flutter project.
3. Copy the DEVELOPMENT_PROMPT.md into your AI coding assistant.

### For Game Balance
1. Reference `planning/02_systems/01_GAMEPLAY_SYSTEMS_BALANCE.md` for all game mechanics and balance values.
2. Use the balance testing checklist before each release.

### For Asset Planning
1. Check `planning/03_assets/01_ASSET_CATALOG_PRODUCTION.md` for the complete asset list.
2. Follow the production roadmap (4 phases) for asset generation.

### For Level Design
1. Review `planning/05_levels/01_LEVEL_DESIGN.md` for campaign structure.
2. Use the JSON data structure to create level definitions.

---

## Uploading to GitHub

To upload this documentation to your GitHub repository:

```bash
# Extract the ZIP file
unzip tower_conquest_planning.zip

# Copy the planning folder to your repo
cp -r planning/ /path/to/your/repo/

# Copy the development prompt
cp DEVELOPMENT_PROMPT.md /path/to/your/repo/

# Commit and push
cd /path/to/your/repo/
git add planning/ DEVELOPMENT_PROMPT.md
git commit -m "Add game design and planning documentation"
git push origin main
```

---

## Document Conventions

- **Markdown Format:** All documents use GitHub-flavored Markdown.
- **Tables:** Used for organizing balance data, asset lists, and specifications.
- **Code Examples:** Dart/Flutter code examples are provided for implementation reference.
- **JSON Format:** Level definitions and data structures use JSON.

---

## Version History

- **v1.0 (July 2026):** Initial planning phase documentation. Complete GDD, balance sheets, asset catalog, implementation guide, and level design.

---

## Support & Updates

This documentation is a living document. As the project evolves, these files will be updated to reflect:
- Gameplay balance changes
- New asset additions
- Implementation discoveries
- Level design refinements

Check the README.md in the planning folder for the latest updates.
