#!/usr/bin/env bash
set -euo pipefail
printf 'Node: '; hostname
printf 'Architecture: '; uname -m
printf 'Kernel: '; uname -r
printf 'Kernel headers: '; if [ -e "/lib/modules/$(uname -r)/build/Makefile" ]; then echo READY; else echo MISSING; fi
printf 'Falco module: '; if lsmod | grep -q '^falco '; then echo LOADED; else echo NOT_LOADED; fi
printf 'Secure Boot (if available): '; mokutil --sb-state 2>/dev/null || true
printf 'Kernel config module support: '; (zgrep '^CONFIG_MODULES=' /proc/config.gz 2>/dev/null || grep '^CONFIG_MODULES=' "/boot/config-$(uname -r)" 2>/dev/null || true)
