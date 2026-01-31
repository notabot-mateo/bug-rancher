# Phase 4: Nursery Economy — PLAN

## Overview

Build out the nursery upgrade system with permanent improvements, consumables, and cosmetics. Introduce daily sell limits to drive hybrid breeding.

---

## Upgrade Categories

### 1. Permanent Facility Upgrades (Linear progression)

| Upgrade | Levels | Effect | Price Scaling |
|---------|--------|--------|---------------|
| Egg Slots | 1 → 2 → 3 | More simultaneous breeding | 500g → 2000g |
| Incubator Speed | 3 levels | -20% / -35% / -50% hatch time | 300g → 800g → 2000g |
| Genetics Lab | 3 levels | +5% / +10% / +15% IV floor boost | 400g → 1200g → 3000g |
| Hybrid Chamber | 2 levels | +10% / +20% hybrid roll chance | 1000g → 3500g |

### 2. Consumables (Buy anytime, single use)

| Item | Effect | Price | Notes |
|------|--------|-------|-------|
| IV Scanner | Reveals exact IVs of one bug | 50g | Use before breeding to pick best parents |
| Fertility Boost | +25% IV floor for next breeding | 150g | Consumed on breed |
| Lucky Charm | +15% hybrid chance for next breeding | 200g | Consumed on breed |
| Instant Hatch | Skip incubation timer | 100g | Emergency skip |

### 3. Cosmetics (Permanent, some with bonuses)

| Item | Effect | Price | Bonus |
|------|--------|-------|-------|
| Cozy Moss Bed | Decoration | 100g | None |
| Crystal Terrarium | Decoration | 250g | +2% sell price |
| Golden Egg Stand | Decoration | 500g | +5% IV floor |
| Rare Specimen Jar | Decoration | 1000g | +5% hybrid chance |
| Trophy Case | Displays best bugs | 750g | None (flex only) |

---

## Daily Sell Limits (NEW MECHANIC)

**Problem:** Player could grind one species forever
**Solution:** Cap sales per species per day

| Species Type | Daily Sell Limit |
|--------------|------------------|
| Base species | 3 per species |
| Hybrids | 5 per species |

**Effect:** Encourages breeding diverse hybrids to maximize daily income

**UI:** Show "2/3 sold today" on sell screen

---

## Tasks

### Task 1: Data Layer
- [ ] Create `upgrades.json` with all upgrade definitions
- [ ] Add upgrade state to player save data
- [ ] Add daily sell tracking to save data
- [ ] Add consumable inventory to save data

### Task 2: Upgrade Manager
- [ ] `upgrade_manager.gd` — handles purchases, effects, persistence
- [ ] Apply incubator speed modifier to breeding
- [ ] Apply IV floor modifier to genetics
- [ ] Apply hybrid chance modifier to breeding rolls

### Task 3: Shop Overhaul
- [ ] Split shop into tabs: Permanent / Consumables / Cosmetics
- [ ] Show upgrade levels and next tier price
- [ ] Grayed out if max level or can't afford
- [ ] Consumable inventory display

### Task 4: Sell Limits
- [ ] Track daily sales per species
- [ ] Reset counter at midnight (or manual reset for testing)
- [ ] Show remaining sells in shop UI
- [ ] Block sale if limit reached

### Task 5: Apply Consumables
- [ ] Breeding screen shows active boosts
- [ ] Consume on breed action
- [ ] IV Scanner modal in collection view

### Task 6: Cosmetics (Stretch)
- [ ] Hatchery decoration slots
- [ ] Apply passive bonuses from equipped cosmetics
- [ ] Visual display (or placeholder)

---

## Success Criteria

- [ ] Can purchase all permanent upgrades
- [ ] Upgrades apply correct effects
- [ ] Consumables work and are consumed
- [ ] Daily sell limits enforced
- [ ] Save/load works for all new data
- [ ] UI clearly shows upgrade progress and limits

---

## My Additions (Riffing on Sean's ideas)

1. **Mutation Serum** (consumable, 300g) — Small chance offspring is random species instead of parents
2. **Species Radar** (permanent, 2000g) — Shows undiscovered species hints in compendium
3. **Bulk Hatcher** (permanent, 1500g) — Hatch all ready eggs with one tap
4. **Breeding Log** (permanent, 400g) — History of all breedings with outcomes

---

*Ready to execute? Or iterate on this plan first?*
