# Bug Rancher 🐛

An idle breeding game where you raise mutant insects, breed them for better stats, and eventually send them on expeditions.

## Status: Pre-Production

Currently in design phase. Working on core systems:
- [x] Base bug roster (10 species)
- [x] Stat system (8 primary stats)
- [ ] Breeding mechanics
- [ ] Incubation timers
- [ ] Facility upgrades
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

- **Base Value**: Species-determined (in `data/bugs.json`)
- **Gene Value (GV)**: 0-31 hidden roll at birth, inherited from parents
- **Mutations**: Rare +/- modifiers from breeding

`Final Stat = Base + GV + Mutations + Facility Bonuses`

## Data Files

- `data/bugs.json` - Base bug roster with stats and abilities

## Tech Stack

- **Engine**: Godot 4.3
- **Language**: GDScript

## Team

- Design & Code: The Canon Factory
- AI Assist: Mateo ([@notabot-mateo](https://github.com/notabot-mateo))

---

*Part of The Canon Factory game dev experiments.*
