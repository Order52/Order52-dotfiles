#!/bin/bash
# ~/.config/waybar/scripts/power_monitor.sh

# Get system power draw from multiple sources
get_system_power() {
    local total_power="0.0"
    
    # Method 1: Try to get AC adapter power (when charging)
    local ac_power="0.0"
    for ac in /sys/class/power_supply/A{C,DP}*; do
        if [[ -d "$ac" ]]; then
            # Some AC adapters have power_now file
            if [[ -f "$ac/power_now" ]]; then
                local ac_power_uw=$(cat "$ac/power_now" 2>/dev/null)
                if [[ -n "$ac_power_uw" && "$ac_power_uw" -gt 0 ]]; then
                    ac_power=$(awk "BEGIN {printf \"%.1f\", $ac_power_uw / 1000000}" 2>/dev/null)
                    break
                fi
            fi
        fi
    done
    
    # Method 2: Get battery power draw
    local battery_power="0.0"
    local battery_status=""
    
    # Get battery status first
    local status_file=$(ls /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)
    if [[ -f "$status_file" ]]; then
        battery_status=$(cat "$status_file" 2>/dev/null | tr '[:upper:]' '[:lower:]')
    fi
    
    # Try power_now file first
    local power_file=$(ls /sys/class/power_supply/BAT*/power_now 2>/dev/null | head -1)
    if [[ -f "$power_file" ]]; then
        local power_uw=$(cat "$power_file" 2>/dev/null)
        if [[ -n "$power_uw" && "$power_uw" -gt 0 ]]; then
            battery_power=$(awk "BEGIN {printf \"%.1f\", $power_uw / 1000000}" 2>/dev/null)
        fi
    fi
    
    # Try upower if power_now didn't work
    if [[ "$battery_power" == "0.0" ]] && command -v upower &> /dev/null; then
        local battery_device=$(upower -e | grep -i bat | head -1)
        if [[ -n "$battery_device" ]]; then
            local upower_rate=$(upower -i "$battery_device" | grep "energy-rate" | awk '{print $2}' | sed 's/W//')
            if [[ -n "$upower_rate" && "$upower_rate" != "0" ]]; then
                battery_power="$upower_rate"
            fi
        fi
    fi
    
    # Method 3: Use powertop for system power if available
    local system_power="0.0"
    if command -v powertop &> /dev/null; then
        # Quick powertop reading (might need sudo)
        local powertop_output=$(timeout 3 powertop --dump --quiet --time=1 2>/dev/null | grep -E "W$" | head -1 | awk '{print $1}' | sed 's/W//')
        if [[ -n "$powertop_output" && "$powertop_output" != "0" ]]; then
            system_power="$powertop_output"
        fi
    fi
    
    # Calculate total power based on what we have
    if [[ "$system_power" != "0.0" ]]; then
        # If we have system power from powertop, use that
        total_power="$system_power"
    elif [[ "$ac_power" != "0.0" ]]; then
        # If we have AC power, use that
        total_power="$ac_power"
    elif [[ "$battery_power" != "0.0" ]]; then
        # If we have battery power, use that
        total_power="$battery_power"
    else
        # Fallback: estimate from CPU usage and base power
        local cpu_usage=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print int(usage)}')
        # Rough estimate: 5W base + CPU usage factor
        total_power=$(awk "BEGIN {printf \"%.1f\", 5 + ($cpu_usage * 0.2)}" 2>/dev/null)
    fi
    
    echo "$total_power"
}

# Get battery status and percentage
get_battery_status() {
    local status_file=$(ls /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)
    if [[ -f "$status_file" ]]; then
        cat "$status_file" 2>/dev/null | tr '[:upper:]' '[:lower:]'
    else
        echo "unknown"
    fi
}

get_battery_percentage() {
    local capacity_file=$(ls /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
    if [[ -f "$capacity_file" ]]; then
        cat "$capacity_file" 2>/dev/null
    else
        echo "N/A"
    fi
}

# Check if AC adapter is connected
is_ac_connected() {
    for ac in /sys/class/power_supply/A{C,DP}*; do
        if [[ -d "$ac" && -f "$ac/online" ]]; then
            local online=$(cat "$ac/online" 2>/dev/null)
            if [[ "$online" == "1" ]]; then
                return 0
            fi
        fi
    done
    return 1
}

# Main execution
power=$(get_system_power)
status=$(get_battery_status)
percentage=$(get_battery_percentage)

# Format the output
text="${power}W"

# Create tooltip based on power source
if is_ac_connected; then
    if [[ "$status" == "full" ]]; then
        tooltip="🔌 AC Power: ${power}W | Battery: ${percentage}% (Full)"
    elif [[ "$status" == "charging" ]]; then
        tooltip="🔌 AC Power: ${power}W | Battery: ${percentage}% (Charging)"
    else
        tooltip="🔌 AC Power: ${power}W | Battery: ${percentage}%"
    fi
else
    tooltip="🔋 Battery Power: ${power}W | ${percentage}% (Discharging)"
fi

# Output JSON for waybar
printf '{"text": "%s", "tooltip": "%s", "class": "power-monitor"}\n' "$text" "$tooltip"
