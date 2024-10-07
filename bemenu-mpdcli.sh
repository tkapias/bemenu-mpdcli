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

# ! arguments are transfered to mpc
# Useful for --host,--port,--partition
# See man mpc
mpc=(mpc --quiet "$@")

mode="queue"
libmode="albumartist"
albumartist=""

header() {
  local current
  current="$("${mpc[@]}" current -f '[%title%|%file%][ (%albumartist%)]')"
  [[ -n "$current" ]] && current=": $current"
  echo -e "󰐎 Play/Pause$current\n󰓛 Stop\n󰒮 Previous\n󰒭 Next"
  [[ "$mode" == "queue"     ]] && echo -e "󰲸 Playlists\n󰌱 Library"
  [[ "$mode" == "playlists" ]] && echo -e "󰐑 Queue\n󰌱 Library"
  [[ "$mode" == "library"   ]] && echo -e "󰐑 Queue\n󰲸 Playlists"
}

list() {
  header
  if [[ "$mode" == "queue" ]]; then
    "${mpc[@]}" playlist -f '%position%\t[%title%|%file%][ (%albumartist% - %album%)]'
  elif [[ "$mode" == "playlists" ]]; then
    "${mpc[@]}" lsplaylists | awk 'NF' | sort -fu
  elif [[ "$mode" == "library" ]] && [[ "$libmode" == "albumartist" ]]; then
    "${mpc[@]}" list albumartist | awk 'NF' | sort -fu
  elif [[ "$mode" == "library" ]] && [[ "$libmode" == "album" ]]; then
    "${mpc[@]}" list album albumartist "$albumartist" | awk 'NF' | sort -fu
  fi
}

list_action() {
  if [[ "$mode" == "queue" ]]; then
    "${mpc[@]}" play "${1%%	*}"
  elif [[ "$mode" == "playlists" ]]; then
    "${mpc[@]}" clear
    "${mpc[@]}" load "$1"
    "${mpc[@]}" play
    mode="queue"
  elif [[ "$mode" == "library" ]] && [[ "$libmode" == "albumartist" ]]; then
    libmode="album"
    albumartist="$1"
  elif [[ "$mode" == "library" ]] && [[ "$libmode" == "album" ]]; then
    "${mpc[@]}" clear
    "${mpc[@]}" find albumartist "$albumartist" album "$1" | sort | "${mpc[@]}" add
    "${mpc[@]}" play
    libmode="albumartist"
    albumartist=""
  fi
}

newmode() {
  if [[ "$1" =~ ^󰐑|^󰐑 ]]; then
    mode="queue"
  elif [[ "$1" =~ ^󰲸|^󰲸 ]]; then
    mode="playlists"
  elif [[ "$1" =~ ^󰌱|^󰌱 ]]; then
    mode="library"
    libmode="albumartist"
    albumartist=""
  else
    false
  fi
}

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
  input=$( list | bemenu -p "󰎆 MPD ${mode^}$([[ $albumartist ]] && echo ": ${albumartist}")")
  [[ -n "$input" ]]
do
  if newmode "$input"; then continue; fi
  if operation "$input"; then continue; fi
  list_action "$input"
done

