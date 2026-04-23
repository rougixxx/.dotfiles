#!/bin/env bash

CURRENT_SUBMAP=$(hyprctl submap)
LINES=()
MAX_LEN=0

modmask_to_string() {
  local mask=$1
  local mods=()

  ((mask & 1)) && mods+=("Shift")
  ((mask & 2)) && mods+=("Caps")
  ((mask & 4)) && mods+=("Ctrl")
  ((mask & 8)) && mods+=("Alt")
  ((mask & 16)) && mods+=("Mod2")
  ((mask & 32)) && mods+=("Mod3")
  ((mask & 64)) && mods+=("Super")
  ((mask & 128)) && mods+=("Mod5")

  local reversed=()
  for ((i = ${#mods[@]} - 1; i >= 0; i--)); do
    reversed+=("${mods[i]}")
  done

  local IFS="+"
  echo "${reversed[*]}"
}

while IFS=$'\t' read -r modmask key desc; do
  key=${key^^}
  [[ -z $key ]] && continue
  mods=$(modmask_to_string "$modmask")
  combo="$key"
  [[ -n $mods ]] && combo="$mods+$key"
  ((${#combo} > MAX_LEN)) && MAX_LEN=${#combo}
  LINES+=("$combo"$'\t'"$desc")
done < <(
  hyprctl -j binds | jq -r --arg sm "$CURRENT_SUBMAP" '.[] | select(.submap == $sm) | [.modmask, (.key // .keycode // .keyname // ""), .description ] | @tsv'
)

OUTPUT=""
for l in "${LINES[@]}"; do
  keys="${l%%$'\t'*}"
  desc="${l#*$'\t'}"
  printf -v keys "%-${MAX_LEN}s" "$keys"
  OUTPUT+="<span font_family=\"monospace\" size=\"7000\"><b>$keys</b> $desc</span>\n"
done

echo -e "$OUTPUT"