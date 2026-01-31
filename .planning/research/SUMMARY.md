# Research Summary

## Stack

- **Engine:** Godot 4.3
- **Language:** GDScript
- **Data:** JSON for static data, Resources for runtime

## Key Findings

### Stat System
- 8 stats: VIT, STR, CAR, SPC, SPD, STA, INS, ADP
- 100 base points per species
- Derived stats: Carry Capacity, Initiative, Crit Chance, Toxicity

### Genetics
- **IVs:** 0-31 per stat, inherited with floor bonus from parents
- **EVs:** 0-252 per stat, 510 total cap, earned through combat
- **Quality:** 5-star rating based on total IV percentage

### Species
10 base bugs designed for distinct roles:
- **Combat:** Bombardier, Trap-Jaw, Assassin, Mantis
- **Carry:** Rhino, Leafcutter, Dung Beetle
- **Traversal:** Diving Beetle, Glowworm, Cicada

### Breeding Combos
Special stat enables elemental attacks from breeding:
- Bombardier + Glowworm → Fire Bomb
- Cicada + Trap-Jaw → Sonic Snap
- Assassin + Diving Beetle → Cryo Venom

## Architecture

```
Main Scene
├── BugCollection (UI)
├── BreedingManager (Logic)
├── BugDatabase (Singleton/Autoload)
└── SaveManager (Persistence)
```

## Comparable Games

- **Pocket Mortys** — Collection + combat loop
- **Tinymon** — Breeding-focused monster game
- **Slime Rancher** — Idle + active hybrid
- **Brotato** — Godot success story, simple loop

---
*Compiled from design session 2026-01-31*
