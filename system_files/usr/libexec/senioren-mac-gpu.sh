#!/usr/bin/bash
# MacBooks with two graphics chips (Intel + Nvidia/AMD): the firmware should always boot
# with the Intel chip. The free Nvidia driver (nouveau) causes display glitches and crashes
# on these machines; with Intel it runs stably and the battery lasts longer.
# Takes effect from the next boot. To undo: delete the file at VAR (chattr -i first).
set -euo pipefail

MODELL=$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)
case "$MODELL" in
    MacBookPro9,1|MacBookPro10,1|MacBookPro11,3|MacBookPro11,5) ;;
    *) echo "Not a MacBook with two graphics chips ($MODELL), nothing to do."; exit 0 ;;
esac

VAR=/sys/firmware/efi/efivars/gpu-power-prefs-fa4ce28d-b62f-4c99-9cc3-6815686e30f9

if [[ -e $VAR ]] && [[ "$(od -An -tx1 "$VAR" | tr -d ' \n')" == "0700000001000000" ]]; then
    echo "$MODELL: Intel graphics already selected."
    exit 0
fi

[[ -e $VAR ]] && chattr -i "$VAR"
# Attributes (NV+BS+RT = 07 00 00 00) + value 1 = integrated graphics, in ONE write
printf '\x07\x00\x00\x00\x01\x00\x00\x00' > "$VAR"
echo "$MODELL: Intel graphics selected. Takes effect after the next reboot."
