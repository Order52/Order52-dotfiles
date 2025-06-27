#!/bin/bash

# Define sinks and card
HEADSET="alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Headphones__sink"
SPEAKER="alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Speaker__sink"
CARD="alsa_card.pci-0000_00_1f.3-platform-skl_hda_dsp_generic"

# Get current default sink
CURRENTSink=$(pactl info | grep 'Default Sink' | awk '{print $3}')

# Toggle output
if [[ "$CURRENTSink" == "$HEADSET" ]]; then
    # Switch to speaker profile and set as default
    pactl set-card-profile "$CARD" "HiFi (HDMI1, HDMI2, HDMI3, Mic1, Mic2, Speaker)"
    pactl set-default-sink "$SPEAKER"

    # Wait for the sink to become available
    sleep 1

    # Set volume to 100%
    pactl set-sink-volume "$SPEAKER" 1.0

    # Unmute if currently muted
    if pactl get-sink-mute "$SPEAKER" | grep -q "yes"; then
        pactl set-sink-mute "$SPEAKER" 0
    fi
else
    # Switch to headset profile and set as default
    pactl set-card-profile "$CARD" "HiFi (HDMI1, HDMI2, HDMI3, Headphones, Mic1, Mic2)"
    pactl set-default-sink "$HEADSET"
fi

