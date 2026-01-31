# Bug Rancher

> An idle breeding game where you raise mutant insects, breed them for better genetics, and send them on expeditions.

## What This Is

A hybrid idle/active game focused on breeding mutant bugs. The core loop is breeding bugs with interesting genetics, watching stats improve over generations, and eventually sending them on runs to gather resources and find new species.

## Core Value

**The ONE thing that must work:** Breeding two bugs and getting an offspring with inherited/mutated stats that feels rewarding to evaluate.

## Who It's For

- Idle game enjoyers who want depth
- Pokemon breeding fans
- People who like incremental progression systems
- Short-session mobile gamers (5-15 min sessions)

## Context

Started as a concept during The Canon Factory game dev discussions. Sean proposed the idea, we refined it to focus on breeding mechanics first before adding the expedition/run layer.

Key insight: Start with the DNA/breeding loop only. The full concept (expeditions, combat) is scope creep for v1.

## Constraints

- **Engine:** Godot 4.3
- **Scope:** Breeding loop only for v1 (no runs/expeditions yet)
- **Team:** Hobby project, no hard deadlines
- **Art:** Placeholder/programmer art acceptable for prototype

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| 8 stats instead of 6 | More variance = more interesting breeding | Implemented |
| "Special" not "Venom" | Opens up elemental combos from breeding | Implemented |
| IV inheritance with floor bonus | Parents matter, but RNG still possible | Implemented |
| 5% × level EV gain chance | Makes combat meaningful without grinding | Implemented |

## Research Completed

See `.planning/research/` for:
- Bug roster (10 species with stats)
- Stat system (8 primary stats)
- Genetics system (IV/EV mechanics)

---
*Last updated: 2026-01-31 after initialization*
