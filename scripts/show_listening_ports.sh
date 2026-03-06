#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/assert_macos.sh"

sudo lsof -iTCP -sTCP:LISTEN -P -n
