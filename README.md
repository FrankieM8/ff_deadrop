# ff_deaddrops

Dead-drop jobs that route through a payphone before revealing the final stash.

## Core loop

1. Use a `burnerphone` or `codednote`.
2. Travel to the assigned payphone.
3. Play the payphone synced scene.
4. Receive the final drop search area.
5. Recover the stash using a synced pickup scene.
6. Get paid out.

## Current V1 scope

- one active drop per player
- standalone payphone phase
- drop variants:
  - `briefcase`
  - `duffel`
  - `crate`
- weighted reward support
- framework support:
  - `qbox`
  - `qbcore`
  - `esx`
- inventory support:
  - `ox_inventory`
  - `qb-inventory`

## Dependencies

- `ox_lib`
- one supported framework
- one supported inventory

## Install

1. Place the resource in your resources folder as `ff_deaddrops`.
2. Add the correct item definitions from:
   - `install/ox_inventory_items.lua`
   - `install/qb_core_items.lua`
3. Set `Config.Framework` and `Config.Inventory` in [config.lua](C:/Users/rowan/Desktop/FM/ff_deaddrops/config.lua) if you do not want auto-detection.
4. Add `ensure ff_deaddrops` to your server config after your framework, inventory, and `ox_lib`.
5. For `ox_inventory`, make sure each item definition uses the same server export name as `Config.Items.Triggers[n].export`.

## Notes

- This resource is standalone and has no witness or dispatch dependency.
- The shipped config defaults to cash payouts first. Item rewards are optional.
- `Config.Items.Triggers.consume = false` is respected by the `qb-inventory` bridge. For `ox_inventory`, item consumption is controlled by the item definition itself.
- `Config.Dev.SceneProfiler` is enabled in the shipped config for timing passes. Turn it off after you finish tuning scene durations.
