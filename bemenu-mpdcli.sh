#!/usr/bin/env bash

#########################
# bemenu-mpdcli
#
# Licence: GNU GPLv3
# Author: Tomasz Kapias
#
# Dependencies:
#   bemenu v0.6.23
#   bemenu-orange-wrapper
#   Nerd-Fonts
#   mpd
#   mpc
#   bash
#   awk
#
#########################

shopt -s extglob

declare -f header list list_action new_mode operation
declare -a mpc bemenu
declare mode libmode albumartist input header_lines line_after_header

# ! all arguments are transfered to mpc
# Useful for --host,--port,--partition
# See man mpc
mpc=(mpc --quiet "$@")
bemenu=(bemenu)
mode="queue"
libmode="albumartist"
albumartist=""
input=""

# 5 first lines for commands/modes
header_lines=5
line_after_header=$(("$header_lines" + 1))
header() {
	local current
	current="$("${mpc[@]}" current -f '[%title%|%file%][ (%albumartist%)]')"
	[[ -n "$current" ]] && current=": $current"
	echo -e "󰐎 Play/Pause$current\n󰓛 Stop\n󰒮 Previous\n󰒭 Next"
	[[ "$mode" == "queue" ]] && echo -e "󰲸 Playlists\n󰌱 Library"
	[[ "$mode" == "playlists" ]] && echo -e "󰐑 Queue\n󰌱 Library"
	[[ "$mode" == "library" ]] && echo -e "󰐑 Queue\n󰲸 Playlists"
}

# append a list from mpc depending on the mode
list() {
	header
	if [[ "$mode" == "queue" ]]; then
		"${mpc[@]}" playlist -f '%position%\t[%title%|%file%][\t(%albumartist% - %album%)]' |
			column --table --separator $'\t' --output-separator $'\t'
	elif [[ "$mode" == "playlists" ]]; then
		"${mpc[@]}" lsplaylists | awk 'NF' | sort -fu
	elif [[ "$mode" == "library" ]] && [[ "$libmode" == "albumartist" ]]; then
		"${mpc[@]}" list albumartist | awk 'NF' | sort -fu
	elif [[ "$mode" == "library" ]] && [[ "$libmode" == "album" ]]; then
		"${mpc[@]}" list album albumartist "$albumartist" | awk 'NF' | sort -fu
	fi
}

# contextual mpc commands on selected line (not in header)
list_action() {
	if [[ "$mode" == "queue" ]]; then
		local index
		index=$(("$header_lines" + 1 + "${1%%[ 	]*}"))
		bemenu+=("--index" "$index")
		"${mpc[@]}" play "${1%%[ 	]*}"
	elif [[ "$mode" == "playlists" ]]; then
		"${mpc[@]}" clear
		"${mpc[@]}" load "$1"
		"${mpc[@]}" play
		mode="queue"
	elif [[ "$mode" == "library" ]] && [[ "$libmode" == "albumartist" ]]; then
		libmode="album"
		albumartist="$1"
		bemenu+=("--index" "$line_after_header")
	elif [[ "$mode" == "library" ]] && [[ "$libmode" == "album" ]]; then
		"${mpc[@]}" clear
		"${mpc[@]}" find albumartist "$albumartist" album "$1" | sort | "${mpc[@]}" add
		"${mpc[@]}" play
		libmode="albumartist"
		albumartist=""
		bemenu+=("--index" "4")
	fi
}

# switch modes from header lines
newmode() {
	if [[ "$1" =~ ^󰐑 ]]; then
		mode="queue"
		bemenu+=("--index" "$line_after_header")
	elif [[ "$1" =~ ^󰲸 ]]; then
		mode="playlists"
		bemenu+=("--index" "$line_after_header")
	elif [[ "$1" =~ ^󰌱 ]]; then
		mode="library"
		bemenu+=("--index" "$line_after_header")
		libmode="albumartist"
		albumartist=""
	else
		false
	fi
}

# mpc player commands from header lines
operation() {
	if [[ "$1" =~ ^󰐎 ]]; then
		"${mpc[@]}" toggle
	elif [[ "$1" =~ ^󰓛 ]]; then
		"${mpc[@]}" stop
	elif [[ "$1" =~ ^󰒮 ]]; then
		"${mpc[@]}" prev
	elif [[ "$1" =~ ^󰒭 ]]; then
		"${mpc[@]}" next
	else
		false
	fi
}

while
	input=$(list | "${bemenu[@]}" -p "󰎆 MPD ${mode^}$([[ $albumartist ]] && echo ": ${albumartist}")")
	[[ -n "$input" ]] # exit if bemenu quit
do
	bemenu=(bemenu) # reset to default --index=0
	if newmode "$input"; then continue; fi
	if operation "$input"; then continue; fi
	list_action "$input"
done
