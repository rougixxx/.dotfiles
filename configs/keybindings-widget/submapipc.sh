#!/bin/env bash

PID="$XDG_RUNTIME_DIR/nwg-submap.pid"

cleanup() {
  rm -f "$PID"
}
trap cleanup EXIT INT TERM

pid_exists() {
  [[ -f $PID ]] || return 1
  read -r pid <"$PID"
  kill -0 "$pid" 2>/dev/null
}

send_signal() {
  local sig=$1
  if pid_exists; then
    read -r pid <"$PID"
    kill -"$sig" "$pid"
  fi
}

start_nwg_wrapper() {
  nwg-wrapper -s ~/dev/bash/submap.sh -l 3 -a start -p right -mt 25 -mr 25 -c ~/dev/bash/style.css &
  echo $! >"$PID"
}

socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" |
  while IFS= read -r line; do
    case "$line" in
    submap\>\>)
      send_signal 2
      echo "$state"
      hyprctl keyword animation "$state"
      ;;
    submap\>\>*)
      if pid_exists; then
        send_signal 8
      else
        state=$(hyprctl -j animations | jq -r '.[][] | select(.name == "layersOut") | "\(.name), \(.enabled), \(.speed), \(.bezier), \(.style)"')
        echo "$state"
        hyprctl keyword animation "layersOut,0"
        start_nwg_wrapper
      fi
      ;;
    esac
  done