# CNC Lathe — LinuxCNC Configuration

LinuxCNC configuration for a Phenix wood lathe converted to CNC. Runs on a Raspberry Pi 4B
using the Byte2Bot Parallel Hat and a 5-axis breakout board, driving two stepper axes (X and Z).

---

## Hardware

| Component | Detail |
|---|---|
| Controller | Raspberry Pi 4B |
| OS / CNC Software | LinuxCNC (AXIS display) |
| Step/Dir Interface | Byte2Bot Parallel Hat + 5-axis DB25 breakout board |
| Stepper Drivers | MicroKinetics DM8078 (×2) — 24–80V, up to 7.8A peak |
| Stepper Motors | 1.8° bipolar 4-lead — 5A per phase |
| Axes | X (cross slide) and Z (carriage along bed) |
| Lead Screws | 4 threads/cm (2.5 mm/rev) |
| Homing | Two homing switches at the minimum end of each axis. Automatic homing: X first, then Z |
| Spindle | 3 fixed mechanical speeds, changed only when fully off. On/off relay via DB25 pin 17 |
| E-Stop | Physical button cuts mains power directly — not connected to GPIO |

---

## Step Scale Calculation

```
Pulses/rev (DM8078 dip switch SW5–SW8):  1600 pul/rev
Lead screw pitch:                         4 threads/cm  →  2.5 mm per revolution
Scale  =  1600 ÷ 2.5  =  640 pulses/mm
```

Both `[JOINT_0]` (X) and `[JOINT_1]` (Z) use `SCALE = 640.0` in `cncLathe.ini`.

---

## DM8078 Dip Switch Settings

### Switches 1–3: Phase Current

Motors are 4-lead bipolar, rated 5A per phase. Target: 7.0A peak / 5.0A RMS.

| Peak | RMS | SW1 | SW2 | SW3 |
|---|---|---|---|---|
| 2.8A | 2.0A | ON | ON | ON |
| 3.5A | 2.5A | OFF | ON | ON |
| 4.2A | 3.0A | ON | OFF | ON |
| 4.9A | 3.5A | OFF | OFF | ON |
| 5.7A | 4.0A | ON | ON | OFF |
| 6.4A | 4.6A | OFF | ON | OFF |
| **7.0A** | **5.0A** | **ON** | **OFF** | **OFF** ← use this |
| 7.8A | 5.6A | OFF | OFF | OFF |

**SW4** — Idle current: OFF = 50% current after 1 s idle (recommended); ON = full current always.

### Switches 5–8: Pulses/Revolution

| Pul/Rev | SW5 | SW6 | SW7 | SW8 |
|---|---|---|---|---|
| 400 | ON | ON | ON | ON |
| 800 | OFF | ON | ON | ON |
| **1600** | **ON** | **OFF** | **ON** | **ON** ← use this |
| 3200 | OFF | OFF | ON | ON |

---

## Pin Mapping (Raspberry Pi Physical Pins)

| Signal | Pi Pin | Direction | Notes |
|---|---|---|---|
| X Step | 21 | Out | |
| X Dir | 19 | Out | |
| Z Step | 31 | Out | |
| Z Dir | 35 | Out | |
| Stepper Enable | 37 | Out | **Inverted** — outputs LOW to enable (DM8078 ENA- is active-LOW) |
| Spindle Relay | 18 | Out | On when M3/M4 commanded |
| X Home Switch | 26 | In | Minimum end of X travel |
| Z Home Switch | 33 | In | Minimum end of Z travel |

---

## Enable Signal

The DM8078 uses an opto-isolated differential enable input. ENA+ is tied to VCC through
a 270Ω resistor; the controller drives ENA- LOW to activate the driver:

- GPIO HIGH → ENA- held HIGH → driver **disabled**
- GPIO LOW  → ENA- pulled LOW → driver **enabled**

LinuxCNC's `amp-enable-out` is HIGH when an axis is enabled, so the output is inverted:

```hal
setp hal_pi_gpio.pin-37-out-invert true
net xenable => hal_pi_gpio.pin-37-out
```

---

## E-Stop

The physical e-stop cuts mains power to the entire system and is not connected to any GPIO.
LinuxCNC uses a software loopback so it starts cleanly:

```hal
net estop-out <= iocontrol.0.user-enable-out
net estop-out => iocontrol.0.emc-enable-in
```

---

## Soft Limits

No hardware limit switches. Limits are enforced in software via `MIN_LIMIT` / `MAX_LIMIT`:

| Axis | Min | Max |
|---|---|---|
| X (cross slide) | −0.001 mm | 100.0 mm |
| Z (carriage) | −800.0 mm | 0.001 mm |

---

## Homing

Both home switches sit at the **minimum** end of their respective axis. LinuxCNC homes
**X first** (sequence 1), then **Z** (sequence 2) after X completes.

### Homing sequence for each axis

1. Move at **−10 mm/s** (toward MIN) until the switch triggers
2. Back off at **+1 mm/s** until the switch releases
3. Creep at **+1 mm/s** until the switch triggers again — this is the latch point
4. Move to `HOME = 0.0`

After homing, machine zero is at the switch location on both axes.

### INI parameters

```ini
HOME_SEARCH_VEL    = -10.0   ; fast move toward switch
HOME_LATCH_VEL     =   1.0   ; slow creep for repeatable latch
HOME_IGNORE_LIMITS =  YES    ; required — no hardware limits to honor
HOME_SEQUENCE      =   1     ; (X) or 2 (Z) — sequential, X first
```

### If the carriage homes away from the headstock

The Z home direction assumes the switch is at the tailstock (far) end of the bed. If your
switch is instead at the headstock end, flip the sign on both Z velocities:

```ini
HOME_SEARCH_VEL = 10.0
HOME_LATCH_VEL  = -1.0
```

---

## Files

| File | Purpose |
|---|---|
| `cncLathe.ini` | Main config — axes, limits, scale, homing, thread periods |
| `cncLathe.hal` | HAL wiring — stepgen, GPIO, spindle, e-stop, homing |
| `custom.hal` | User HAL additions (not overwritten by stepconf) |
| `custom_postgui.hal` | Post-GUI HAL additions (not overwritten by stepconf) |
| `postgui_call_list.hal` | Loads `custom_postgui.hal` after GUI starts |
| `pyvcp_options.hal` | Sets `spindle-at-speed` signal |
| `tool.tbl` | Tool table (diameter and Z offset per tool) |
| `linuxcnc.var` | G-code coordinate system variables |

---

## Bugs Fixed

### E-stop loopback — machine was stuck in e-stop on every startup

`iocontrol.0.emc-enable-in` was driven from a net (`estop-ext`) that was never connected
to anything, leaving LinuxCNC permanently in e-stop.

```hal
# Before (broken):
net estop-out <= iocontrol.0.user-enable-out
net estop-ext => iocontrol.0.emc-enable-in   # estop-ext was never driven

# After (fixed):
net estop-out <= iocontrol.0.user-enable-out
net estop-out => iocontrol.0.emc-enable-in
```

### Enable pin invert — stepper drivers were never enable-controlled

DM8078 ENA- is active-LOW but `pin-37-out-invert` was commented out. With it disabled,
LinuxCNC's HIGH enable signal held ENA- HIGH, keeping both drivers permanently disabled.

```hal
# Before (broken):
#setp hal_pi_gpio.pin-37-out-invert true

# After (fixed):
setp hal_pi_gpio.pin-37-out-invert true
```

### Unused HAL modules removed

`charge_pump`, `sum2`, and `not` were loaded but never wired or added to any thread.
Removed as leftover router artifacts.

---

## Router-to-Lathe Conversion Summary

| Change | Detail |
|---|---|
| stepgen instances | 3 → 2 (X, Z only) |
| Y axis | All step/dir pins, joint params, and home switch removed |
| Z joint number | `joint.2` / `stepgen.2` → `joint.1` / `stepgen.1` |
| A, B axes | Wiring commented out |
| Spindle | PWM removed; on/off relay only |
| Limit switches | All hardware inputs removed; soft limits used instead |

---

## Reference

- [Byte2Bot Parallel Hat Setup](https://byte2bot.com/blogs/instructions/setting-up-and-troubleshooting-the-pi-parallel-hat)
- [MicroKinetics DM8078 Manual](https://www.microkinetics.com) — M036 Rev A5
- [LinuxCNC HAL Reference](https://linuxcnc.org/docs/html/hal/halmodule.html)
- [LinuxCNC stepgen](https://linuxcnc.org/docs/html/man/man9/stepgen.9.html)
- [LinuxCNC Homing](https://linuxcnc.org/docs/html/config/ini-homing.html)
