#!/bin/bash

# Check dependencies
if ! command -v yad >/dev/null 2>&1; then
  echo "Error: Yad is not installed. Install it with 'yay -S yad'."
  exit 1
fi
if ! command -v awk >/dev/null 2>&1; then
  echo "Error: awk is not installed. Install it with 'sudo pacman -S gawk'."
  exit 1
fi
if ! command -v xrandr >/dev/null 2>&1; then
  echo "Error: awk is not installed. Install it with 'sudo pacman -S gawk'."
  exit 1
fi

# Detect the connected output (assuming one monitor)
output=$(xrandr | grep " connected" | awk '{print $1}' | head -n 1)
if [ -z "$output" ]; then
  echo "Error: No connected monitor found!"
  exit 1
fi

# Function to get current brightness and gamma
get_current_settings() {
  verbose=$(xrandr --verbose)
  brightness=$(echo "$verbose" | grep -m1 Brightness | awk '{printf "%.1f", $2}')
  gamma=$(echo "$verbose" | grep -m1 Gamma | awk '{print $2}')
  if [ -z "$brightness" ] || [ -z "$gamma" ]; then
    echo "Error: Could not retrieve current brightness or gamma!"
    exit 1
  fi

  # Parse gamma values (reported as inverse)
  IFS=':' read -r r_inv g_inv b_inv <<< "$gamma"
  r=$(awk -v x="$r_inv" 'BEGIN {printf "%.1f", (x != 0) ? 1/x : 1}')
  g=$(awk -v x="$g_inv" 'BEGIN {printf "%.1f", (x != 0) ? 1/x : 1}')
  b=$(awk -v x="$b_inv" 'BEGIN {printf "%.1f", (x != 0) ? 1/x : 1}')
  avg=$(awk -v r="$r" -v g="$g" -v b="$b" 'BEGIN {printf "%.1f", (r + g + b)/3}')
}

# Function to apply xrandr settings
apply_settings() {
  local bright=$1 red=$2 green=$3 blue=$4
  xrandr --output "$output" --brightness "$bright" --gamma "$red:$green:$blue" 2>/dev/null
  # Store applied values
  echo "$bright|$red|$green|$blue" > /tmp/last_brightness_gamma
  echo "xrandr --output $output --brightness $bright --gamma $red:$green:$blue" > "$tmp_cmd"
}

# Main loop to keep the dialog open after Apply
while true; do
  # Get current settings
  get_current_settings

  # Temporary file for command display
  tmp_cmd=$(mktemp)
  echo "xrandr --output $output --brightness $brightness --gamma $r:$g:$b" > "$tmp_cmd"

  # Yad dialog with sliders (one decimal place)
  result=$(yad --form \
    --title="Brightness GUI" \
    --width=300 \
    --field="Brightness:NUM" "$brightness!0.0..2.0!0.1!1" \
    --field="Gamma (All):NUM" "$avg!0.1..3.0!0.1!1" \
    --field="Gamma (Red):NUM" "$r!0.1..3.0!0.1!1" \
    --field="Gamma (Green):NUM" "$g!0.1..3.0!0.1!1" \
    --field="Gamma (Blue):NUM" "$b!0.1..3.0!0.1!1" \
    --field="\nCurrent Command::TXT" "$(cat "$tmp_cmd")" \
    --button="Apply:1" \
    --on-top \
    --separator="|" \
    --always-print-result)

  # Check yad exit status
  yad_exit_status=$?
  if [ $yad_exit_status -eq 252 ]; then
    # X button clicked, exit the script
    rm -f "$tmp_cmd"
    exit 0
  fi

  # Process the yad output
  IFS='|' read -r bright all red green blue cmd <<< "$result"
  # If "All" slider changed, override individual RGB values
  if [ -n "$all" ] && [ "$(awk -v a="$all" -v b="$avg" 'BEGIN {print (a != b) ? 1 : 0}')" -eq 1 ]; then
    red=$all
    green=$all
    blue=$all
  fi
  # Apply settings only if values are non-empty
  if [ -n "$bright" ] && [ -n "$red" ] && [ -n "$green" ] && [ -n "$blue" ]; then
    apply_settings "$bright" "$red" "$green" "$blue"
  fi

  # Clean up temporary file
  rm -f "$tmp_cmd"
done
