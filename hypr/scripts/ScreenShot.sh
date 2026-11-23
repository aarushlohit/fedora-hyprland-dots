#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Screenshots scripts

# variables
time=$(date "+%d-%b_%H-%M-%S")
PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
dir="$PICTURES_DIR/Screenshots"
file="Screenshot_${time}_${RANDOM}.png"

iDIR="$HOME/.config/swaync/icons"
iDoR="$HOME/.config/swaync/images"
sDIR="$HOME/.config/hypr/scripts"

active_window_class=$(hyprctl -j activewindow | jq -r '(.class)')
active_window_file="Screenshot_${time}_${active_window_class}.png"
active_window_path="${dir}/${active_window_file}"

notify_cmd_base="notify-send -t 10000 -A action1=Open -A action2=Delete -h string:x-canonical-private-synchronous:shot-notify"
notify_cmd_shot="${notify_cmd_base} -i ${iDIR}/picture.png "
notify_cmd_shot_win="${notify_cmd_base} -i ${iDIR}/picture.png "
notify_cmd_NOT="notify-send -u low -i ${iDoR}/note.png "

# notify and view screenshot
notify_view() {
	local target="$1"
	if [[ -n "$target" && -e "$target" ]]; then
		wl-copy -t image/png < "$target" 2>/dev/null || true
		(canberra-gtk-play -i camera-shutter 2>/dev/null || paplay /usr/share/sounds/freedesktop/stereo/camera-shutter.oga 2>/dev/null || true) &
		notify-send -a "Screenshot" "Screenshot Captured" "Saved to $(basename "$target") and copied to clipboard" -i "$target" -t 3000 &
	else
		notify-send -u low -a "Screenshot" "Screenshot" "Cancelled or not saved" -t 2000 &
	fi
}

# countdown
countdown() {
	for sec in $(seq $1 -1 1); do
		notify-send -h string:x-canonical-private-synchronous:shot-notify -t 1000 -i "$iDIR"/timer.png  " Taking shot" " in: $sec secs"
		sleep 1
	done
}

close_quickshell_overlay() {
	qs -c ii ipc call overlay close 2>/dev/null || true
	sleep 0.3
}

# take shots
shotnow() {
	close_quickshell_overlay
	local target="${dir}/${file}"
	grim -o "$(hyprctl activeworkspace -j | jq -r .monitor)" "$target" 2>/dev/null || grim "$target"
	notify_view "$target"
}

shot5() {
	countdown '5'
	close_quickshell_overlay
	local target="${dir}/${file}"
	sleep 1 && (grim -o "$(hyprctl activeworkspace -j | jq -r .monitor)" "$target" 2>/dev/null || grim "$target")
	notify_view "$target"
}

shot10() {
	countdown '10'
	close_quickshell_overlay
	local target="${dir}/${file}"
	sleep 1 && (grim -o "$(hyprctl activeworkspace -j | jq -r .monitor)" "$target" 2>/dev/null || grim "$target")
	notify_view "$target"
}

shotwin() {
	close_quickshell_overlay
	local w_pos w_size
	w_pos=$(hyprctl activewindow | grep 'at:' | cut -d':' -f2 | tr -d ' ' | tail -n1)
	w_size=$(hyprctl activewindow | grep 'size:' | cut -d':' -f2 | tr -d ' ' | tail -n1 | sed s/,/x/g)
	local target="${dir}/${file}"
	grim -g "$w_pos $w_size" "$target"
	notify_view "$target"
}

shotarea() {
	close_quickshell_overlay
	local geom
	geom=$(slurp) || return 0
	[[ -z "$geom" ]] && return 0
	local target="${dir}/${file}"
	grim -g "$geom" "$target"
	notify_view "$target"
}

shotactive() {
	close_quickshell_overlay
	local win_geom
	win_geom=$(hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
	[[ -z "$win_geom" || "$win_geom" == "null" ]] && return 0
	local target="${dir}/${file}"
	grim -g "$win_geom" "$target"
	notify_view "$target"
}

shotswappy() {
	close_quickshell_overlay
	local geom
	geom=$(slurp) || return 0
	[[ -z "$geom" ]] && return 0
	local tmpfile
	tmpfile=$(mktemp --suffix=.png)
	grim -g "$geom" "$tmpfile"
	if [[ -s "$tmpfile" ]]; then
		wl-copy -t image/png < "$tmpfile"
		(canberra-gtk-play -i camera-shutter 2>/dev/null || paplay /usr/share/sounds/freedesktop/stereo/camera-shutter.oga 2>/dev/null || true) &
		swappy -f "$tmpfile"
		rm -f "$tmpfile"
	fi
}

if [[ ! -d "$dir" ]]; then
	mkdir -p "$dir"
fi

if [[ "$1" == "--now" ]]; then
	shotnow
elif [[ "$1" == "--in5" ]]; then
	shot5
elif [[ "$1" == "--in10" ]]; then
	shot10
elif [[ "$1" == "--win" ]]; then
	shotwin
elif [[ "$1" == "--area" ]]; then
	shotarea
elif [[ "$1" == "--active" ]]; then
	shotactive
elif [[ "$1" == "--swappy" ]]; then
	shotswappy
else
	echo -e "Available Options : --now --in5 --in10 --win --area --active --swappy"
fi

exit 0
