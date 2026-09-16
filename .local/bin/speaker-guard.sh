#!/bin/sh
# Speaker protection guard — enforces safe ALSA hardware levels at boot
# Prevents CS35L41 amp overdrive that can blow speakers
# Generated 2026-07-09 after speaker replacement
# Updated 2026-07-13: always set Master to ceiling (not just cap),
#   since WirePlumber soft-mixer means hardware levels are fixed and
#   the user adjusts volume via software only.

CARD=1
MASTER=70          # 80% of 87 — safe ceiling with headroom
SPEAKER_LEFT=75    # L/R balance compensation for Gen 10 speaker
SPEAKER_RIGHT=87
PCM=252            # 99% — near max but not pegged

# Wait for ALSA card to be available
for i in $(seq 1 10); do
    if amixer -c $CARD scontents >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

# Set Master to the safe ceiling (always, not just when above)
amixer -c $CARD cset numid=16 $MASTER >/dev/null 2>&1

# Set L/R speaker balance
amixer -c $CARD cset numid=9 ${SPEAKER_LEFT},${SPEAKER_RIGHT} >/dev/null 2>&1

# Set PCM level
amixer -c $CARD cset numid=24 $PCM >/dev/null 2>&1

# Ensure speakers are unmuted
amixer -c $CARD cset numid=17 on >/dev/null 2>&1
amixer -c $CARD set Speaker unmute >/dev/null 2>&1
