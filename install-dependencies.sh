#!/usr/bin/env bash
set -euo pipefail
xargs sudo apt-get -y install < dependencies.txt
