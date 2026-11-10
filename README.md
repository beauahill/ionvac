# ionvac

Local control for the ionvac SmartClean robo vac V2 (Tzumi model 8026):
ESPHome (LibreTiny) on the Tuya WR3 WiFi module, talking TuyaMCU to the vac's
main MCU, controlled from Home Assistant with no Tuya cloud.

- `esphome/ionvac-v2.yaml`: device config (board `wr3`, LibreTiny pinned to 1.9.2)
- `esphome/secrets.yaml.example`: copy to `secrets.yaml` (gitignored)
- `docs/flashing.md`: cloudcutter, stock dump, and UART flashing with ltchiptool
- `docs/datapoints.md`: worksheet for mapping the V2's Tuya datapoints
- `scripts/compile.sh`: build (generates throwaway secrets if none exist)

Navigation stays on the vac's own MCU. Only the WiFi module firmware is replaced.
