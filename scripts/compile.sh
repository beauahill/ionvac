#!/usr/bin/env bash
# Compile the ESPHome config. If esphome/secrets.yaml is missing (CI / cloud
# sessions), a throwaway one with dummy values is generated so the build can
# run. Never flash a build made with dummy secrets.
set -euo pipefail
cd "$(dirname "$0")/../esphome"
created=0
if [ ! -f secrets.yaml ]; then
  key=$(python3 -c 'import base64,os;print(base64.b64encode(os.urandom(32)).decode())')
  sed "s#REPLACE_WITH_32_BYTE_BASE64_KEY#${key}#" secrets.yaml.example > secrets.yaml
  created=1
fi
trap '[ "$created" = 1 ] && rm -f secrets.yaml' EXIT
esphome compile "${1:-ionvac-v2.yaml}"
