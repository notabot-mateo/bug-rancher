# Phase 1: Bug Collection — Context

## Sean's Vision

### Two-Tier Collection System

**Tier 1: Species Compendium (Grid)**
- Grid layout of bug sprites
- One slot per species
- Undiscovered species are greyed out / locked
- New discoveries feel like unlocks

**Tier 2: Individual Bugs (Card Hand)**
- Click a species in compendium
- See all your bugs of that type as cards
- Scroll through like a hand of cards
- Above cards: species description (guidebook entry)

### Card Design

**Front of Card:**
- Bug sprite
- Name (and nickname if set)
- Star rating (1-5)
- Highest stat highlighted

**Back of Card:**
- Full 8-stat breakdown
- IVs visible
- (EVs later when combat exists)

### Starter Bug

- **Isopod** added as starter species
- Given on first launch
- Balanced/beginner-friendly stats
- High ADP (survives anywhere)

## Requirements Covered

- CORE-01: Player can own and view bugs ✓ (two-tier system)
- CORE-02: Bug displays stats, IVs, quality ✓ (card back)
- UI-01: Main screen shows collection ✓ (compendium grid)
- UI-02: Bug detail view ✓ (card flip)
- UI-05: Star rating visible ✓ (card front)

## Design Notes

The compendium approach is smart because:
1. Makes species discovery feel meaningful
2. Scales well (can add species without UI changes)
3. Separates "what exists" from "what you have"
4. Guidebook entries add world-building

---
*Captured: 2026-01-31*
