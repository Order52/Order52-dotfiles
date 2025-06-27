#!/bin/bash

# Define sink names
HEADPHONE_SINK="alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Headphones__sink"
SPEAKER_SINK="alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Speaker__sink"

# Define card name
CARD="alsa_card.pci-0000_00_1f.3-platform-skl_hda_dsp_generic"

# Get current default sink
CURRENT_SINK=$(pactl get-default-sink)

if [ "$CURRENT_SINK" = "$HEADPHONE_SINK" ]; then
    echo "Switching to Speakers..."
    pactl set-card-profile "$CARD" "HiFi (HDMI1, HDMI2, HDMI3, Mic1, Mic2, Speaker)"
    pactl set-default-sink "$SPEAKER_SINK"
else
    echo "Switching to Headphones..."
    pactl set-card-profile "$CARD" "HiFi (HDMI1, HDMI2, HDMI3, Headphones, Mic1, Mic2)"
    pactl set-default-sink "$HEADPHONE_SINK"
fi
