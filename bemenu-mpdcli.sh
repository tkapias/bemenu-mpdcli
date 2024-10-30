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
#   exiftool
#   bash
#   awk
#
#########################

shopt -s extglob

declare -f header list list_action new_mode operation
declare -a mpc bemenu
declare mode libmode albumartist input header_lines line_after_header library_path

# ! all arguments are transfered to mpc
# Useful for --host,--port,--partition
# See man mpc
mpc=(mpc --quiet "$@")
bemenu=(bemenu)
mode="queue"
libmode="albumartist"
albumartist=""
input=""
# Music folder path for lyrics to work,
# default to XDG_MUSIC_DIR if defined,
# or by thevariable MPD_LIBRARY_PATH
library_path="${MPD_LIBRARY_PATH:-$XDG_MUSIC_DIR}"

# 5 first lines for commands/modes
header_lines=6
line_after_header=$(("$header_lines" + 1))
header() {
	local current
	current=$("${mpc[@]}" current -f '[%title%|%name%|%file%][ (%albumartist%)]')
	[[ -n "$current" ]] && current=": $current"
	/usr/bin/echo -e "󰐎 Play/Pause$current\n󰓛 Stop\n󰒮 Previous\n󰒭 Next"
	[[ "$mode" == "queue" ]] && /usr/bin/echo -e "󰲸 Playlists\n󰌱 Library\n󰯂 Lyrics"
	[[ "$mode" == "playlists" ]] && /usr/bin/echo -e "󰐑 Queue\n󰌱 Library\n󰯂 Lyrics"
	[[ "$mode" == "library" ]] && /usr/bin/echo -e "󰐑 Queue\n󰲸 Playlists\n󰯂 Lyrics"
	[[ "$mode" == "lyrics" ]] && /usr/bin/echo -e "󰐑 Queue\n󰲸 Playlists\n󰌱 Library"
}

# append a list from mpc depending on the mode
list() {
	header
	if [[ "$mode" == "queue" ]]; then
		"${mpc[@]}" playlist -f '%position%\t[%title%|%name%|%file%][\t(%albumartist% - %album%)]' |
			column --table --separator $'\t' --output-separator $'\t'
	elif [[ "$mode" == "playlists" ]]; then
		"${mpc[@]}" lsplaylists | /usr/bin/awk 'NF' | sort -fu
	elif [[ "$mode" == "library" ]] && [[ "$libmode" == "albumartist" ]]; then
		"${mpc[@]}" list albumartist | /usr/bin/awk 'NF' | sort -fu
	elif [[ "$mode" == "library" ]] && [[ "$libmode" == "album" ]]; then
		"${mpc[@]}" list album albumartist "$albumartist" | /usr/bin/awk 'NF' | sort -fu
	elif [[ "$mode" == "lyrics" ]]; then
		local current lyrics
		current="${library_path}/$("${mpc[@]}" current -f '%file%')"
		# shellcheck disable=SC2016
		[[ -f "$current" ]] && lyrics=$(/usr/bin/exiftool -if '$SynchronizedLyricsText-xxx' -SynchronizedLyricsText-xxx -q -b "$current")
		if [[ -n "$lyrics" ]] && [[ -f "$current" ]]; then
			/usr/bin/paste \
				<(/usr/bin/printf %s "$lyrics" | /usr/bin/sed -r 's/^(\[[0-9\.]*\])(.*)$/\1/') \
				<(/usr/bin/printf %s "$lyrics" | /usr/bin/sed 's/^\[[0-9\.]*\]//') |
				/usr/bin/column --table --separator $'\t'
		elif [[ -f "$current" ]]; then
			# shellcheck disable=SC2016
			lyrics=$(/usr/bin/exiftool -if '$Lyrics-xxx' -Lyrics-xxx -q -b "$current" | /usr/bin/tr -d '\r')
			if [[ -n "$lyrics" ]]; then
				/usr/bin/printf '%s' "$lyrics"
			else
				/usr/bin/printf '%s' "󰌑 No Lyrics found in the file."
			fi
		else
			/usr/bin/printf '%s' "󰌑 No file to extract Lyrics."
		fi
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
	elif [[ "$mode" == "lyrics" ]]; then
		local time line index
		time=$(/usr/bin/printf %s "$1" | /usr/bin/sed -nr '/^\[[0-9]/ s/^[.+[^0-9]([0-9]{1,3}\.[0-9]{3})\].*/\1/p')
		if [[ -n "$time" ]]; then
			"${mpc[@]}" seek "${time%%\.[0-9]*}"
			line=$(exiftool -SynchronizedLyricsText-xxx -q -b "${library_path}/$("${mpc[@]}" current -f '%file%')" |
				/usr/bin/grep -n -- "${time}]" | /usr/bin/cut -f1 -d:)
			index=$(("$header_lines" + "$line"))
			bemenu+=("--index" "$index")
		else
			mode="queue"
			bemenu+=("--index" "$line_after_header")
		fi
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
	elif [[ "$1" =~ ^󰯂 ]]; then
		mode="lyrics"
		bemenu+=("--index" "4")
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
	input=$(list | "${bemenu[@]}" -p "󰎆 MPD ${mode^}$([[ $albumartist ]] && /usr/bin/echo ": ${albumartist}")")
	[[ -n "$input" ]] # exit if bemenu quit
do
	bemenu=(bemenu) # reset to default --index=0
	if newmode "$input"; then continue; fi
	if operation "$input"; then continue; fi
	list_action "$input"
done
