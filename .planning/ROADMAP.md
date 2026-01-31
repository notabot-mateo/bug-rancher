# Roadmap

## Overview

| Phase | Name | Goal | Requirements | Status |
|-------|------|------|--------------|--------|
| 0 | Foundation | Backend systems ready | DATA-02 | ✅ Done |
| 1 | Bug Collection | View and inspect owned bugs | CORE-01, CORE-02, UI-01, UI-02, UI-05 | 🔜 Next |
| 2 | Breeding | Core breeding loop working | CORE-03, CORE-04, CORE-05, UI-03, UI-04 | Pending |
| 3 | Economy | Sell bugs, earn currency | CORE-06, PROG-01, PROG-04 | Pending |
| 4 | Upgrades | Facility progression | PROG-02, PROG-03 | Pending |
| 5 | Polish | Save/load, balancing | DATA-01 | Pending |

---

## Phase 0: Foundation ✅

**Goal:** Core data structures and backend systems

**Requirements:** DATA-02

**Delivered:**
- 10 bug species with base stats (bugs.json)
- BugDatabase for loading/querying species
- BugInstance class for individual bugs
- Genetics system (IV/EV calculations)
- BreedingManager with slots and incubation

**Success Criteria:**
- [x] Can create wild bugs with random IVs
- [x] Can create offspring with inherited IVs
- [x] IV floor calculation works correctly
- [x] Quality rating system functional

---

## Phase 1: Bug Collection 🔜

**Goal:** Player can view their bugs and see stats

**Requirements:** CORE-01, CORE-02, UI-01, UI-02, UI-05

**Success Criteria:**
- [ ] Main scene loads with bug collection visible
- [ ] Can scroll through owned bugs
- [ ] Tapping bug shows detail view
- [ ] Detail view shows all 8 stats + IVs
- [ ] Star rating visible on collection view
- [ ] At least 3 starter bugs given on first launch

---

## Phase 2: Breeding

**Goal:** Core breeding loop functional

**Requirements:** CORE-03, CORE-04, CORE-05, UI-03, UI-04

**Success Criteria:**
- [ ] Can select two bugs for breeding
- [ ] Preview shows expected IV floors before confirming
- [ ] Egg appears in breeding slot with timer
- [ ] Timer counts down in real-time (or accelerated for testing)
- [ ] Hatching produces bug with correct genetics
- [ ] Offspring appears in collection

---

## Phase 3: Economy

**Goal:** Currency system and bug selling

**Requirements:** CORE-06, PROG-01, PROG-04

**Success Criteria:**
- [ ] Currency displayed in UI
- [ ] Can sell bugs from collection
- [ ] Sale price varies by quality (stars)
- [ ] Currency persists between scenes

---

## Phase 4: Upgrades

**Goal:** Facility progression system

**Requirements:** PROG-02, PROG-03

**Success Criteria:**
- [ ] Upgrade menu accessible
- [ ] Can purchase faster incubation
- [ ] Can unlock breeding slot 2
- [ ] Can unlock breeding slot 3
- [ ] Upgrades persist and apply correctly

---

## Phase 5: Polish

**Goal:** Save/load and game feel

**Requirements:** DATA-01

**Success Criteria:**
- [ ] Game saves automatically on key actions
- [ ] Game loads correctly on startup
- [ ] Incubation timers continue while away (offline progress)
- [ ] No obvious bugs or crashes
- [ ] Ready for playtesting

---
*Last updated: 2026-01-31*
