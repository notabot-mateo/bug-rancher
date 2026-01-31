# Bug Rancher 🐛

An idle breeding game where you raise mutant insects, breed them for better stats, and eventually send them on expeditions.

## Status: Pre-Production

Currently in design phase. Working on core systems:
- [x] Base bug roster (10 species)
- [x] Stat system (8 primary stats)
- [x] IV/EV genetics system
- [x] Breeding mechanics
- [x] Incubation timers
- [ ] Facility upgrades
- [ ] Combat system
- [ ] Run/expedition system (future)

## Stat System

| Stat | Abbr | Description |
|------|------|-------------|
| Vitality | VIT | HP pool, survival |
| Strength | STR | Melee damage, carry weight |
| Carapace | CAR | Physical defense |
| Special | SPC | Elemental/magic damage, unique abilities |
| Speed | SPD | Dodge, attack speed, turn order |
| Stamina | STA | Action economy, endurance |
| Instinct | INS | Detection, loot find, ambush resist |
| Adaptation | ADP | Mutation chance, environment resist |

Each bug has 100 base stat points distributed across these 8 stats.

## Genetics System

### IVs (Individual Values)
- Range: 0-31 per stat
- **Wild bugs**: Completely random IVs
- **Bred bugs**: Parents influence offspring's IV floor
  - Formula: `floor = avg(parent_a_iv, parent_b_iv) × 0.25`
  - Example: Two parents with 28 STR IV → offspring STR IV floor is 7

### EVs (Effort Values)
- Range: 0-252 per stat, 510 total cap
- Earned through combat
- Chance to gain: `5% × enemy_level`
- Gain amount: 4 EVs per successful roll
- EVs are assigned to the defeated enemy's primary stat

### Stat Calculation
```
Final Stat = (Base × level_scale) + (IV × level_scale) + (EV × 0.25 × level_scale)
where level_scale = 1.0 + (level / 100)
```

### Quality Ratings
| Rating | IV Total | Stars |
|--------|----------|-------|
| Perfect | 95%+ | ⭐⭐⭐⭐⭐ |
| Great | 80-94% | ⭐⭐⭐⭐ |
| Good | 60-79% | ⭐⭐⭐ |
| Common | 40-59% | ⭐⭐ |
| Trash | <40% | ⭐ |

## Project Structure

```
bug-rancher/
├── data/
│   └── bugs.json           # Base bug roster with stats
└── scripts/
    ├── bug_database.gd     # Loads/queries bug species data
    ├── bug_instance.gd     # Individual bug with IVs/EVs
    ├── genetics.gd         # IV inheritance, EV training, stat calc
    └── breeding_manager.gd # Breeding slots, incubation, hatching
```

## Tech Stack

- **Engine**: Godot 4.3
- **Language**: GDScript

## Team

- Design & Code: The Canon Factory
- AI Assist: Mateo ([@notabot-mateo](https://github.com/notabot-mateo))

---

*Part of The Canon Factory game dev experiments.*
