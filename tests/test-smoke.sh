#!/usr/bin/bash
# Confirm the dependency-free shell test harness works.
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/testlib.sh"
pass 'test harness'
