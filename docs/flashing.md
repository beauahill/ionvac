# Flashing the WR3 (RTL8710BN) with ESPHome / LibreTiny

Two routes. Try **A (cloudcutter)** first. If it fails, use **B (UART)**.
Either way, **get a full stock dump before writing anything** (B.3). Cloudcutter
can't dump the stock firmware, so if A works you still have no backup. That is
acceptable because the dump only matters for going back to Tuya.

## 0. Build the firmware

Run everything from inside the repo checkout:

```bash
git clone https://github.com/beauahill/ionvac.git
cd ionvac
python3 -m venv .venv && . .venv/bin/activate
pip install esphome==2026.10.2 ltchiptool==4.15.0
cp esphome/secrets.yaml.example esphome/secrets.yaml
```

Edit `esphome/secrets.yaml`. Fill `api_encryption_key` and
`ota_encryption_key` with two **different** values from
`openssl rand -base64 32`, then compile:

```bash
esphome compile esphome/ionvac-v2.yaml
```

For UART flashing on Linux, give your user access to serial ports once (then
log out and back in): `sudo usermod -aG dialout $USER`.

The output lands in `esphome/.esphome/build/ionvac-v2/.pioenvs/ionvac-v2/`:

| File | Use it for |
|---|---|
| `firmware.uf2` | UART flash with ltchiptool (route B), and ESPHome/web OTA |
| `image_ota1.0x00B000.bin`, `image_ota2.0x0D0000.bin` | Raw OTA slot images. Check which file cloudcutter wants (A.2) |

Verified: this config builds with LibreTiny 1.9.2 on ESPHome 2026.10.2 (flash
60% used, so OTA has headroom).

`scripts/compile.sh` compiles with throwaway secrets if `secrets.yaml` is
missing. That is for CI and cloud sessions only. **Never flash a build made
with dummy secrets**, because you won't be able to reach it on WiFi.

## A. tuya-cloudcutter (OTA, no disassembly)

Only works on RTL8710BN units with **unpatched** Tuya firmware. Expect it to
fail if the vac took app updates after ~Feb 2022, or if it runs SDK 2.0.0.

### A.1 Requirements
- A Linux machine (a Raspberry Pi works) with a **WiFi adapter that supports AP
  mode**, plus Docker and NetworkManager.
- The vac **removed from the Tuya/Smart Life app**. Cloudcutter needs it
  unpaired.

```bash
git clone https://github.com/tuya-cloudcutter/tuya-cloudcutter
cd tuya-cloudcutter
```

### A.2 Choose the firmware to send
Cloudcutter loads custom firmware from its `custom-firmware/` folder. Two options:

1. **ESPHome Kickstart (simplest).** Cloudcutter ships or links LibreTiny's
   minimal "kickstart" ESPHome image. After flashing it, the device opens an AP
   with a web UI. Upload your own `firmware.uf2` (or OTA from ESPHome) from
   there. This avoids file-format guesswork.
2. **Your own build.** Copy the LibreTiny OTA image that cloudcutter accepts
   for RTL8710BN into `custom-firmware/`. Confirm the expected file type against
   cloudcutter's README and the LibreTiny "flashing with cloudcutter" docs for
   your versions. It is not the `.uf2`, and the requirement has changed between
   releases.

### A.3 Run it
```bash
sudo ./tuya-cloudcutter.sh -r      # -r: reset NetworkManager when done
```
1. Choose **Flash 3rd Party Firmware**.
2. Choose the device profile. Search for "Tzumi" / "ionvac" / "SmartClean". If
   nothing matches, choose "by firmware version" and pick the RTL8710BN entry
   matching the version shown in the Tuya app (note it **before** unpairing).
3. Choose your firmware file (A.2).
4. Put the vac in **AP pairing mode** when prompted: hold the WiFi or power
   button until the LED blinks fast (EZ mode), then hold again until it blinks
   **slowly** (AP mode). Cloudcutter needs the slow-blink AP mode.
5. Cloudcutter joins the vac's `SmartLife-XXXX` AP, runs the exploit, and serves
   the firmware.

**If it stalls at "waiting for device" or the exploit fails,** the firmware
is probably patched. Move to route B. A failed cloudcutter attempt does not
brick the device.

### A.4 After success
Connect to the kickstart AP (or `ionvac-v2 Fallback`), set WiFi, then OTA your
real `firmware.uf2`. Then go to "First boot" below.

## B. UART flashing with ltchiptool (fallback)

### B.1 Hardware
- A **3.3V** USB serial adapter (CP2102, CH340 with a 3.3V jumper, FT232). **Not 5V.**
- Jumper wires or pogo pins. You may need a fine soldering iron for the module pads.

### B.2 Wiring
Open the top shell and find the WR3 module.

| USB-serial | WR3 pad | Notes |
|---|---|---|
| GND | GND | Always connect |
| TX | **RX2** (PA29) | Flash/log UART |
| RX | **TX2** (PA30) | Flash/log UART |
| 3.3V | VCC | **Only with the vac battery disconnected**. See below. |

**Power:** pick one. Either power the module from the adapter's 3.3V with the
vac's battery **unplugged** (adapter must supply ≥300 mA; weak adapters cause
random link failures), or leave the vac powered from its own board and connect
**GND + TX/RX only**. Never feed 3.3V into a powered vac board.

**TX0/RX0 go to the Tuya MCU.** Don't connect the adapter there. If the MCU
chatters during flashing it can disturb the link. If flashing is flaky with the
vac powered, use the battery-unplugged method.

**Download mode:** hold **TX2 low (to GND)** while powering up or pulsing
**CEN** to GND, then release. ltchiptool can also try to enter download mode on
its own if you just power-cycle when it prompts. Try that first.

### B.3 Dump the stock firmware FIRST
```bash
mkdir -p dumps
ltchiptool flash info realtek-ambz -d /dev/ttyUSB0          # sanity check: should report 2 MiB flash
ltchiptool flash read realtek-ambz dumps/wr3-stock-$(date +%F).bin -d /dev/ttyUSB0
ltchiptool flash read realtek-ambz dumps/wr3-stock-$(date +%F)-2.bin -d /dev/ttyUSB0
cmp dumps/wr3-stock-$(date +%F).bin dumps/wr3-stock-$(date +%F)-2.bin && echo "dumps match"
```
- Read twice and compare. A matching pair means the dump is trustworthy.
- The dump contains the device's Tuya **auth key and local key**. Store it
  safely, off git (`dumps/` and `*.bin` are gitignored).
- Optional: `ltchiptool flash split wr3 dumps/wr3-stock-YYYY-MM-DD.bin` splits
  the dump by partition. The Tuya config partition can reveal the stock
  firmware version and DP schema hints.

### B.4 Flash ESPHome
```bash
ltchiptool flash write esphome/.esphome/build/ionvac-v2/.pioenvs/ionvac-v2/firmware.uf2 -d /dev/ttyUSB0
```
ltchiptool reads the family and offsets from the UF2. Power-cycle with TX2 no
longer held low.

### B.5 Restore stock (if ever needed)
```bash
ltchiptool flash write -f realtek-ambz -s 0x0 dumps/wr3-stock-YYYY-MM-DD.bin -d /dev/ttyUSB0
```

## First boot

1. If WiFi credentials fail, join the `ionvac-v2 Fallback` AP and use the
   captive portal.
2. Watch logs: `esphome logs esphome/ionvac-v2.yaml` (over WiFi), or the
   adapter on TX2 at 115200.
3. **Baud check.** A working link logs `tuya` lines like `Product: '{"p":...'`
   and `Datapoint N update to ...` shortly after boot. If you see
   `Initialization failed` or no tuya lines at all, change `tuya_baud` from
   `"9600"` to `"115200"`, rebuild, and OTA. Uncommenting the
   `tuya: VERY_VERBOSE` logger lines shows raw frames, which helps here.
4. **If nothing arrives from the MCU at either baud,** you may be hitting the
   LibreTiny RX bug the 1.9.2 pin works around. Confirm `LibreTiny Version`
   reads 1.9.2. If it does, look for a newer fixed release.
5. The tuya `dump_config` output at boot lists every DP the MCU announced, with
   its type. Copy it into `docs/datapoints.md`.
