#!/usr/bin/bash
# MacBooks mit zwei Grafikchips (Intel + Nvidia/AMD): Die Firmware soll immer mit dem
# Intel-Chip starten. Der freie Nvidia-Treiber (nouveau) verursacht auf diesen Geräten
# Bildfehler und Abstürze; mit Intel läuft es stabil und der Akku hält länger.
# Wirkt ab dem nächsten Start. Rückgängig: die Datei unter VAR löschen (chattr -i vorher).
set -euo pipefail

MODELL=$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)
case "$MODELL" in
    MacBookPro9,1|MacBookPro10,1|MacBookPro11,3|MacBookPro11,5) ;;
    *) echo "Kein MacBook mit zwei Grafikchips ($MODELL), nichts zu tun."; exit 0 ;;
esac

VAR=/sys/firmware/efi/efivars/gpu-power-prefs-fa4ce28d-b62f-4c99-9cc3-6815686e30f9

if [[ -e $VAR ]] && [[ "$(od -An -tx1 "$VAR" | tr -d ' \n')" == "0700000001000000" ]]; then
    echo "$MODELL: Intel-Grafik ist bereits eingestellt."
    exit 0
fi

[[ -e $VAR ]] && chattr -i "$VAR"
# Attribute (NV+BS+RT = 07 00 00 00) + Wert 1 = integrierte Grafik, in EINEM Schreibvorgang
printf '\x07\x00\x00\x00\x01\x00\x00\x00' > "$VAR"
echo "$MODELL: Intel-Grafik eingestellt. Wirkt nach dem nächsten Neustart."
