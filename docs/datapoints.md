# Datapoint map (ionvac SmartClean V2)

Fill this in from the ESPHome logs, then use it to add the entities
(step 3: tuya switch/select/sensor entities and the HA template vacuum).

DP numbers from the SmartClean 2000 config are **not** assumed to match the V2.

## How to capture
1. `esphome logs esphome/ionvac-v2.yaml`
2. Copy the boot-time `tuya` config dump (lists every DP and its type).
3. Do **one** action at a time (remote button, dock, pick up the vac, let the
   battery drain), and note which `Datapoint N update to X` lines appear.
4. Record raw values exactly as logged, including enum numbers and bitmasks.

## Boot dump
```
(paste the "Datapoint N: type ..." lines here)
```

## Observations

| DP | Type (bool/int/enum/string/raw/bitmask) | Action that triggered it | Values seen | Guess |
|---|---|---|---|---|
|  |  | Press START on remote |  | power / switch_go |
|  |  | Press PAUSE / START again |  | pause |
|  |  | Press DOCK / home |  | return to dock |
|  |  | Change mode (auto/spot/edge/...) |  | mode enum |
|  |  | Change suction (if the remote has it) |  | fan speed enum |
|  |  | Idle, docked, charging |  | status enum / battery % |
|  |  | Lift the vac / stuck on obstacle |  | fault bitmask |
|  |  | Ignore (periodic) |  | clean time / area / consumables |

## Status enum values

| Value | Meaning |
|---|---|
|  |  |
