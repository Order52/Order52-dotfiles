#!/bin/sh

status=$(playerctl status 2>/dev/null)
class=$(echo "$status" | tr '[:upper:]' '[:lower:]')
icon=""

if [ "$class" = "playing" ]; then
  info=$(playerctl metadata --format '{{artist}} - {{title}}')
  if [ ${#info} -gt 40 ]; then
    info=$(echo "$info" | cut -c1-40)"..."
  fi
  text="$info $icon"
elif [ "$class" = "paused" ]; then
  text=$icon
else
  text=""
  class="stopped"
fi

echo -e "{\"text\":\"$text\", \"class\":\"$class\"}"

