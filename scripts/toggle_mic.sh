#!/bin/bash

# Toggle microphone mute state
pamixer --default-source --toggle-mute

# Get current mute status (true = muted, false = unmuted)
MIC_STATE=$(pamixer --default-source --get-mute)

if [ "$MIC_STATE" = "true" ]; then
    notify-send -u low -i microphone-sensitivity-high -t 1000 "Microphone" "Muted"
else
    notify-send -u low -i microphone-sensitivity-high -t 1000 "Microphone" "Unmuted"
fi
