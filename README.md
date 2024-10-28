# bemenu-mpdcli

A [bemenu](https://github.com/Cloudef/bemenu) client for [MPD](https://github.com/MusicPlayerDaemon/MPD) using [mpc](https://github.com/MusicPlayerDaemon/mpc). Control you local or remote Music Player Daemon from a simple and fast menu.

![preview](assets/preview.png)

The preview uses my wrapper for bemenu: [bemenu-orange-wrapper](https://github.com/tkapias/bemenu-orange-wrapper).

## Dependencies

- [MPD](https://github.com/MusicPlayerDaemon/MPD)
- [mpc](https://github.com/MusicPlayerDaemon/mpc)
- [bemenu >= 0.6](https://github.com/Cloudef/bemenu)
- [xclip](https://github.com/astrand/xclip)
- [Nerd Fonts (Symbols Only)](https://github.com/ryanoasis/nerd-fonts/releases/latest)
- Bash >= 5
- Awk
- exiftool

### Optional

- [bemenu-orange-wrapper](https://github.com/tkapias/bemenu-orange-wrapper)

## Installation

```bash
git clone --depth 0 https://github.com/tkapias/bemenu-mpdcli.git bemenu-mpdcli
cd bemenu-mpdcli
chmod +x bemenu-mpdcli.sh
```

- Optional: Symlink to a directory in your user's path:

```bash
ln -s $PWD/bemenu-mpdcli.sh $HOME/.local/bin/bemenu-mpdcli
```

## Features

- Display current title, albumartist (or url/filename).
- Player commands: Play/Pause, Stop, Prev, Next.
- Queue:
  - List position, title, albumartist, album (or url/filename).
  - Play selected.
- Playlists:
  - List mpd playlists by filename.
  - Replace queue with a playlist and play it.
- Library:
  - List albumartist.
  - List albums for a selected albumartist.
  - Replace queue with an album and play it.
- Lyrics:
  - Display lyrics included in current song's file.
  - Parse SynchronizedLyricsText-xxx or Lyrics-xxx tags.
  - Prefer Synchronized Lyrics if available.
  - Seek position in current song from a line in Synchronized Lyrics.

## Usage

bemenu-mpdcli shoould work out of the box for a local mpd server.

You can also provide arguments to mpc for custom locations.

```bash
[MPD_LIBRARY_PATH=$HOME/Music] bemenu-mpdcli [--host ip/socket] [--port num] [--partition name]
```

### Lyrics

For the lyrics extraction to work, you need exiftool and a way for
bemenu-mpdcli to locate the root folder of the MPD library.
You can declare the path to this folder as the env variable
`MPD_LIBRARY_PATH` or let it use XDG_MUSIC_DIR by default if it's defined
by your session manager.

You can also source your custom XDG user directories in your `.profile`,
`.xsession` or `.bashrc` files:

```bash
# set -a to export the sourced variables
set -a
. ${HOME}/.config/user-dirs.dirs
set +a
```

### Integrations

- Binding example for bemenu-mpdcli in i3wm:

```i3wm
bindsym $mod+m exec --no-startup-id "bemenu-mpdcli"
```

