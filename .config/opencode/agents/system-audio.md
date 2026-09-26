---
description: >
  System audio troubleshooting for this HP laptop — use when diagnosing
  distorted sound, missing devices, volume problems, or speaker/amp issues.
  Covers the CS35L41 smart amplifier setup, ALSA/PipeWire stack, and known
  failure modes.
---

## Hardware: HP laptop with CS35L41 smart amplifiers

This laptop (SSID 103c:8c71) has:
- **ALC245** HDA codec (Realtek) — handles headphone jack and routes to speakers
- **2× CS35L41** Class-D smart amplifiers (Cirrus Logic) — drive the built-in speakers via I2C
- AMD Ryzen HD Audio Controller (PCI c3:00.6) — the main audio card (ALSA card 1)
- AMD Radeon HDMI audio (PCI c3:00.1) — HDMI/DP audio, normally set to profile `off`

The speakers are driven *through* the CS35L41 amps, not directly by the HDA codec.
Headphones bypass the CS35L41 entirely (HDA codec node 0x02).

### Critical failure mode: blown speakers from ALSA level reset

If the SSD is swapped or ALSA state is lost, all mixer levels reset to 100% (0dB).
The CS35L41 amps receive a full-scale signal and can **physically blow the speakers**
within minutes. This has happened once (July 2026) — both speakers were destroyed.

### Safe ALSA levels (enforced by boot guard)

| Control          | Safe value      | Notes |
| ---------------- | ---------------- | ----- |
| Master           | 70/87 (~80%)    | Hard ceiling. Never exceed. |
| Speaker (L)      | 75/87           | L/R balance — left speaker is louder (Gen 10 replacement) |
| Speaker (R)      | 87/87           | |
| PCM              | 252/255 (~99%)  | Near max but not pegged |

The boot guard service (`~/.config/systemd/user/speaker-guard.service`) runs at
login and enforces these. The script is at `~/.local/bin/speaker-guard.sh`.
Adjust `MASTER` in that script if the ceiling needs to change.

### WirePlumber soft-mixer (prevents hardware level override)

WirePlumber was overriding the guard's ALSA levels by restoring saved route
volumes and by mapping DE volume-slider changes to ALSA hardware controls.
This wiped the L/R speaker balance and could push Master above the safe ceiling.

The fix is `api.alsa.soft-mixer = true` on the Ryzen audio card, set via a
WirePlumber device rule at `~/.config/wireplumber/wireplumber.conf.d/51-soft-mixer.conf`.

With soft-mixer enabled:
- WirePlumber uses **software volume only** — DE volume slider changes do NOT
  touch the ALSA hardware mixer
- The hardware mixer levels (Master, Speaker, PCM) are fixed at boot by the
  guard script and never change unless `amixer` is used directly
- Port switching (headphone vs speaker) still works — the mixer is still used
  to mute unused paths
- The user's volume range is 0–100% of the safe ceiling, not 0–100% of full scale

### How to find the distortion threshold with new speakers

1. Set Master low (20-30%)
2. Run `speaker-test -c 2 -r 48000 -f 440 -t sine -l 1` and listen for clean tone
3. Increase Master in 5-10% increments, repeating the test
4. Stop at the first sign of distortion/warbling
5. Set the safe ceiling ~10% below that threshold
6. Run `sudo alsactl store` to persist

### CS35L41 diagnostics

Kernel log (via `journalctl -k`) shows amp binding on boot. Key fields:

```
CS35L41 Bound - SSID: 103C8C71, BST: 1, VSPK: <0|1>, CH: <L|R>, FW EN: 1, SPKID: -19
```

- `BST: 1` = boost enabled (both should be 1)
- `VSPK` = voltage booster status (asymmetry between L/R can indicate a hardware fault)
- `SPKID: -19` = speaker ID detection failed (uses fallback tuning — this is normal for this model)
- `Gain: 17` = DSP gain setting

ALSA controls for the amps:
- `R0/L0 DSP1 Firmware Load` — toggle to reload DSP firmware
- `R0/L0 DSP1 Firmware Type` — spk-prot (default), spk-cali, spk-diag, misc
- `R0/L0 Forced Mute Status` — read-only fault indicator

Firmware files are built into the kernel (not from firmware-cirrus package):
- `cs35l41-dsp1-spk-prot-103c8c71.wmfw.zst` — DSP firmware
- `cs35l41-dsp1-spk-prot-103c8c71.bin.zst` — tuning data
- `.bincfg` tuning file is missing — driver uses built-in fallback (normal)

## PipeWire / WirePlumber stack

- PipeWire 1.6.7 with WirePlumber 0.5.x
- No user PipeWire or WirePlumber config (all defaults)
- PulseAudio compatibility layer via `pipewire-pulse`
- Default sink: `alsa_output.pci-0000_c3_00.6.analog-stereo`
- Default source: `alsa_input.pci-0000_c3_00.6.analog-stereo`

### Clean device setup

The Radeon HDMI card should be set to profile `off` to avoid clutter:
```
pactl set-card-profile alsa_card.pci-0000_c3_00.1 off
pactl set-card-profile alsa_card.pci-0000_c3_00.6 output:analog-stereo+input:analog-stereo
```

### Key commands

| Task | Command |
|------|---------|
| Check status | `wpctl status` |
| Check volume | `wpctl get-volume @DEFAULT_AUDIO_SINK@` |
| Set volume | `wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.5` |
| Inspect sink | `wpctl inspect @DEFAULT_AUDIO_SINK@` |
| ALSA levels | `amixer -c 1 scontents` |
| Test tone | `speaker-test -c 2 -r 48000 -f 440 -t sine -l 1` |
| Kernel audio log | `journalctl -k \| grep -iE "cs35l41\|snd_hda\|alc"` |
| Codec dump | `cat /proc/asound/card1/codec#0` |
| Persist ALSA | `sudo alsactl store` |
| Reload audio services | `systemctl --user restart pipewire pipewire-pulse wireplumber` |

### Troubleshooting decision tree

1. **Distortion on speakers only, headphones fine?** → CS35L41 amp or speaker hardware issue. Check kernel log for VSPK asymmetry. Test at increasing volumes to find threshold. If threshold is very low, speakers are damaged.

2. **Distortion on both speakers and headphones?** → Signal chain issue. Check ALSA Master/PCM levels, PipeWire volume, sample rate.

3. **No sound at all?** → Check profiles (`pactl list cards`), check if amps are forced muted (`amixer -c 1 cget numid=3` and `numid=6`), check if DSP firmware loaded.

4. **Missing microphone?** → Card profile is probably output-only. Set to `output:analog-stereo+input:analog-stereo`.

5. **Too many devices in GUI?** → Radeon card is probably on `pro-audio` profile. Set it to `off`.

6. **Distortion after SSD swap or ALSA reset?** → Levels reset to 100%. This can blow speakers. Check ALSA levels immediately and restore safe values. The boot guard should catch this, but verify manually.
