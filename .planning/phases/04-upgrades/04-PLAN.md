# Phase 4: Nursery Economy — TECHNICAL PLAN

## Overview

Implement the upgrade system with permanent improvements, consumables, cosmetics, and daily sell limits.

---

## 1. Data Layer

### 1.1 New File: `data/upgrades.json`

```json
{
  "permanent": {
    "egg_slots": {
      "name": "Egg Slots",
      "description": "Additional breeding slots",
      "max_level": 3,
      "base_value": 1,
      "per_level": 1,
      "prices": [0, 500, 2000]
    },
    "incubator_speed": {
      "name": "Incubator Speed",
      "description": "Faster egg hatching",
      "max_level": 3,
      "effect_type": "multiply",
      "base_value": 1.0,
      "per_level": [-0.20, -0.35, -0.50],
      "prices": [300, 800, 2000]
    },
    "genetics_lab": {
      "name": "Genetics Lab", 
      "description": "IV floor boost when breeding",
      "max_level": 3,
      "effect_type": "add",
      "base_value": 0,
      "per_level": [0.05, 0.10, 0.15],
      "prices": [400, 1200, 3000]
    },
    "hybrid_chamber": {
      "name": "Hybrid Chamber",
      "description": "Increased hybrid breeding chance",
      "max_level": 2,
      "effect_type": "add",
      "base_value": 0.50,
      "per_level": [0.10, 0.20],
      "prices": [1000, 3500]
    }
  },
  "consumables": {
    "iv_scanner": {
      "name": "IV Scanner",
      "description": "Reveal exact IVs of one bug",
      "price": 50,
      "stack_max": 99
    },
    "fertility_boost": {
      "name": "Fertility Boost",
      "description": "+25% IV floor for next breeding",
      "price": 150,
      "effect": {"iv_floor_bonus": 0.25},
      "stack_max": 10
    },
    "lucky_charm": {
      "name": "Lucky Charm",
      "description": "+15% hybrid chance for next breeding",
      "price": 200,
      "effect": {"hybrid_chance_bonus": 0.15},
      "stack_max": 10
    },
    "instant_hatch": {
      "name": "Instant Hatch",
      "description": "Skip incubation timer",
      "price": 100,
      "stack_max": 10
    }
  },
  "cosmetics": {
    "moss_bed": {"name": "Cozy Moss Bed", "price": 100, "bonus": null},
    "terrarium": {"name": "Crystal Terrarium", "price": 250, "bonus": {"sell_bonus": 0.02}},
    "egg_stand": {"name": "Golden Egg Stand", "price": 500, "bonus": {"iv_floor_bonus": 0.05}},
    "specimen_jar": {"name": "Rare Specimen Jar", "price": 1000, "bonus": {"hybrid_chance_bonus": 0.05}}
  }
}
```

### 1.2 Player Data Changes (`game_manager.gd`)

```gdscript
var player_data: Dictionary = {
    # Existing...
    "currency": 0,
    "discovered_species": [],
    "collection": [],
    
    # NEW - Upgrades
    "upgrade_levels": {
        "egg_slots": 1,
        "incubator_speed": 0,
        "genetics_lab": 0,
        "hybrid_chamber": 0
    },
    
    # NEW - Consumables
    "consumables": {
        "iv_scanner": 0,
        "fertility_boost": 0,
        "lucky_charm": 0,
        "instant_hatch": 0
    },
    
    # NEW - Cosmetics
    "owned_cosmetics": [],
    "equipped_cosmetics": [],
    
    # NEW - Daily limits
    "daily_sells": {},  # species_id -> count
    "last_sell_reset": 0  # unix timestamp
}
```

---

## 2. New Scripts

### 2.1 `scripts/upgrade_manager.gd`

```gdscript
extends Node
class_name UpgradeManager

var _upgrade_data: Dictionary = {}

func _ready() -> void:
    _load_upgrade_data()

func _load_upgrade_data() -> void:
    # Load from upgrades.json
    pass

# PERMANENT UPGRADES
func get_upgrade_level(upgrade_id: String) -> int
func get_max_level(upgrade_id: String) -> int
func get_upgrade_price(upgrade_id: String) -> int  # Price for NEXT level
func can_purchase_upgrade(upgrade_id: String) -> bool
func purchase_upgrade(upgrade_id: String) -> bool

# EFFECTS (computed from levels + cosmetics)
func get_egg_slot_count() -> int  # Base 1 + upgrade level
func get_incubation_multiplier() -> float  # 1.0 = normal, 0.5 = 50% faster
func get_iv_floor_bonus() -> float  # 0.0 to ~0.20
func get_hybrid_chance_bonus() -> float  # 0.0 to ~0.25
func get_sell_price_bonus() -> float  # 0.0 to ~0.02

# CONSUMABLES
func get_consumable_count(item_id: String) -> int
func use_consumable(item_id: String) -> bool
func add_consumable(item_id: String, count: int) -> void
func purchase_consumable(item_id: String) -> bool

# COSMETICS
func owns_cosmetic(cosmetic_id: String) -> bool
func purchase_cosmetic(cosmetic_id: String) -> bool
func equip_cosmetic(cosmetic_id: String) -> void
func get_equipped_cosmetics() -> Array

# DAILY LIMITS
func get_daily_sell_count(species_id: String) -> int
func get_daily_sell_limit(species_id: String) -> int  # 3 for base, 5 for hybrid
func can_sell_species_today(species_id: String) -> bool
func record_sale(species_id: String) -> void
func check_daily_reset() -> void  # Reset if new day
```

---

## 3. Modified Scripts

### 3.1 `scripts/game_manager.gd` Changes

```gdscript
# Add to _initialize_new_game():
player_data["upgrade_levels"] = {"egg_slots": 1, ...}
player_data["consumables"] = {}
player_data["owned_cosmetics"] = []
player_data["daily_sells"] = {}
player_data["last_sell_reset"] = Time.get_unix_time_from_system()
```

### 3.2 `scripts/breeding_screen.gd` Changes

```gdscript
# In _on_breed_pressed():
var iv_bonus = UpgradeManager.get_iv_floor_bonus()
# Check for active fertility_boost consumable
if _active_fertility_boost:
    iv_bonus += 0.25
    UpgradeManager.use_consumable("fertility_boost")
    _active_fertility_boost = false

# Apply to IV generation...

# In _calculate_incubation_time():
var base_time = INCUBATION_SECONDS
var multiplier = UpgradeManager.get_incubation_multiplier()
return int(base_time * multiplier)

# In hybrid roll:
var hybrid_chance = 0.50 + UpgradeManager.get_hybrid_chance_bonus()
# Check for lucky_charm...
```

### 3.3 `scripts/hybrid_generator.gd` Changes

```gdscript
# In roll_breeding_outcome():
func roll_breeding_outcome(parent_a: String, parent_b: String, bonus: float = 0.0) -> Dictionary:
    var hybrid_chance = 0.50 + bonus  # Pass in from breeding_screen
    # Use hybrid_chance instead of hardcoded 0.50
```

### 3.4 `scripts/shop_screen.gd` Changes

```gdscript
# Add tab switching for: Sell | Upgrades | Consumables | Cosmetics

# In calculate_price():
var bonus = UpgradeManager.get_sell_price_bonus()
return int(base_price * (1.0 + bonus))

# In _on_sell_pressed():
if not UpgradeManager.can_sell_species_today(bug.species_id):
    # Show "Limit reached" message
    return
UpgradeManager.record_sale(bug.species_id)

# Show "2/3 sold today" per species
```

---

## 4. UI Changes

### 4.1 Shop Screen Tabs
- **Sell**: Existing sell UI + daily limit indicators
- **Upgrades**: Grid of permanent upgrades with level/price/buy button
- **Items**: Consumables + cosmetics in sub-sections

### 4.2 Breeding Screen Additions
- Show active boosts: "🧬 Fertility Boost active!"
- Boost toggle buttons if consumables owned
- Multiple egg slots (based on upgrade)

### 4.3 Collection Screen Additions
- "🔍 Scan" button on bug cards (uses IV Scanner)

---

## 5. Implementation Order

| Step | Task | Files | Est. Lines |
|------|------|-------|------------|
| 1 | Create upgrades.json | data/ | ~80 |
| 2 | Create upgrade_manager.gd | scripts/ | ~200 |
| 3 | Add upgrade data to player save | game_manager.gd | ~30 |
| 4 | Add UpgradeManager autoload | project.godot | ~1 |
| 5 | Implement daily sell limits | upgrade_manager.gd, shop_screen.gd | ~50 |
| 6 | Add upgrade shop tab | shop_screen.tscn/gd | ~150 |
| 7 | Add consumable shop tab | shop_screen.tscn/gd | ~100 |
| 8 | Apply incubation speed modifier | breeding_screen.gd | ~10 |
| 9 | Apply IV floor modifier | breeding_screen.gd, genetics | ~20 |
| 10 | Apply hybrid chance modifier | breeding_screen.gd, hybrid_generator.gd | ~20 |
| 11 | Consumable activation UI | breeding_screen.gd | ~50 |
| 12 | IV Scanner modal | collection_screen.gd | ~80 |
| 13 | Cosmetics (stretch) | shop_screen.gd, upgrade_manager.gd | ~100 |

**Total estimate:** ~900 lines

---

## 6. Success Criteria

- [ ] Can purchase permanent upgrades, levels persist
- [ ] Egg slots upgrade adds breeding slots
- [ ] Incubator speed reduces hatch time
- [ ] Genetics lab increases IV floor
- [ ] Hybrid chamber increases hybrid chance
- [ ] Can buy and use consumables
- [ ] IV Scanner reveals exact IVs
- [ ] Fertility Boost applies to next breed
- [ ] Lucky Charm applies to next breed
- [ ] Daily sell limits enforced (3 base / 5 hybrid)
- [ ] Sell limits reset at midnight
- [ ] All data saves and loads correctly

---

*Ready to execute.*
