#!/bin/bash
# ~/.config/waybar/modules/gpu-temp-fan.sh
# Combined GPU temperature and fan speed monitor for Waybar

# SysFS path for fan speed (from your Predator Sense script)
FAN_SYSFS_PATH="/sys/module/linuwu_sense/drivers/platform:acer-wmi/acer-wmi/predator_sense/fan_speed"

# Get GPU temperature
get_gpu_temp() {
    local temp=""
    
    # Try nvidia-smi first (faster and doesn't require X)
    if command -v nvidia-smi &>/dev/null; then
        temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d '\n')
    fi
    
    # Fallback to nvidia-settings if needed
    if [[ -z "$temp" || "$temp" == "0" ]] && command -v nvidia-settings &>/dev/null; then
        temp=$(DISPLAY=:0 nvidia-settings -q gpucoretemp -t 2>/dev/null | head -1 | tr -d '\n')
    fi
    
    echo "$temp"
}

# Get GPU fan speed percentage
get_gpu_fan_speed() {
    local fan_speed=""
    
    # Check if the fan speed sysfs path exists
    if [ -f "$FAN_SYSFS_PATH" ]; then
        # Read the fan speed value (format: "cpu_speed,gpu_speed")
        fan_data=$(cat "$FAN_SYSFS_PATH" 2>/dev/null)
        if [ -n "$fan_data" ]; then
            # Extract GPU fan speed (second value after comma)
            fan_speed=$(echo "$fan_data" | cut -d',' -f2)
            # Handle special case for auto mode (0,0)
            if [ "$fan_speed" = "0" ]; then
                fan_speed="Auto"
            else
                fan_speed="${fan_speed}%"
            fi
        fi
    fi
    
    # Fallback if no fan data available
    if [ -z "$fan_speed" ]; then
        fan_speed="N/A"
    fi
    
    echo "$fan_speed"
}

# Get status based on temperature
get_status() {
    local temp=$1
    
    if [[ $temp -lt 50 ]]; then
        echo "❄️" "cold"
    elif [[ $temp -lt 70 ]]; then
        echo "🟢" "good"
    elif [[ $temp -lt 80 ]]; then
        echo "🟡" "warm"
    elif [[ $temp -lt 85 ]]; then
        echo "🟠" "hot"
    else
        echo "🔥" "critical"
    fi
}

# Main execution
temp=$(get_gpu_temp)
fan=$(get_gpu_fan_speed)

# Handle missing temperature data
if [[ -z "$temp" || "$temp" == "0" ]]; then
    echo "{\"text\":\"🔍 GPU N/A | 🌀 $fan\",\"class\":\"unknown\",\"tooltip\":\"GPU temperature not available\"}"
    exit 0
fi

# Get status
read icon class <<< "$(get_status "$temp")"

# Output JSON for waybar
echo "{\"text\":\"$icon ${temp}°C | 🌀 $fan\",\"class\":\"$class\",\"tooltip\":\"GPU: ${temp}°C\\nGPU Fan: $fan\"}"
