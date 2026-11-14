#!/usr/bin/env bash
curr_workspace="$(hyprctl activeworkspace -j | jq -r ".id")"
dispatcher="$1"
shift ## The target is now in $1, not $2

if [[ -z "${dispatcher}" || "${dispatcher}" == "--help" || "${dispatcher}" == "-h" || -z "$1" ]]; then
  echo "Usage: $0 <dispatcher> <target>"
  exit 1
fi
if [[ "$1" == *"+"* || "$1" == *"-"* ]]; then ## Is this something like r+1 or -1?
  target="$1"
elif [[ "$1" =~ ^[0-9]+$ ]]; then ## Is this just a number?
  target=$((((curr_workspace - 1) / 10 ) * 10 + $1))
else
  target="$1"
fi

case "${dispatcher}" in
  workspace)
    hyprctl dispatch "hl.dsp.focus({ workspace = \"${target}\" })"
    ;;
  movetoworkspace)
    hyprctl dispatch "hl.dsp.window.move({ workspace = \"${target}\", follow = true })"
    ;;
  movetoworkspacesilent)
    hyprctl dispatch "hl.dsp.window.move({ workspace = \"${target}\", follow = false })"
    ;;
  *)
    hyprctl dispatch "${dispatcher} ${target}"
    ;;
esac
