# Proposal: add-trinkets

## What
Add a Trinket system: one-shot consumable items (max 2 per run) activatable during a throw. Implement 2 M1 trinkets: **Re-Tumble** (re-roll all unlocked dice mid-window) and **Freeze Timer** (pause the current lock window for 2 s).

## Why
PRD §3.4: "Trinkets (max 2) — one-shot consumables (e.g., re-tumble, freeze timer, duplicate a die)." Trinkets add tactical depth and a second purchase category in the shop.

## Capabilities affected
- **NEW** `trinkets` spec — Trinket resource, TrinketInventory, activation protocol
- **MODIFIED** `shop-scene` spec — trinket offers in pool
- **MODIFIED** `throw-loop` spec — trinket activation buttons visible during lock windows

## Non-goals
- "Duplicate a die" trinket (M2)
- Trinket carries across rounds (they're consumed on use)
