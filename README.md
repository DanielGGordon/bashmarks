### Bashmarks is a shell script that allows you to save and jump to commonly used directories. Now supports tab completion.

This is a fork of [huyng/bashmarks](https://github.com/huyng/bashmarks) that adds an interactive fuzzy-finder bookmark selector (`ll`) and modernizes the internals for better performance by using an in-memory associative array instead of re-sourcing and piping through `env` on every call.

## Dependencies

- **fzf** — required for the `ll` interactive selector. Install with your package manager:
  - Debian/Ubuntu: `sudo apt install fzf`
  - macOS: `brew install fzf`
  - Arch: `sudo pacman -S fzf`
  - Windows (Git Bash): `scoop install fzf` or `choco install fzf`. Note: `--height` is not supported on Windows, so `ll` will open full-screen. You may also need to run `export TERM=xterm-256color` in your `.bashrc` for mintty compatibility. See the [fzf Windows wiki](https://github.com/junegunn/fzf/wiki/Windows) for details.

All other commands (`s`, `g`, `p`, `d`, `l`) work without fzf.

## Install

1. `git clone https://github.com/DanielGGordon/bashmarks.git`
2. `cd bashmarks`
3. `make install`
4. source **~/.local/bin/bashmarks.sh** from within your **~.bash\_profile** or **~/.bashrc** file
5. you can now remove the downloaded `bashmarks` folder which is no longer needed

## Demo

![ll interactive bookmark selector](demo/ll_demo.gif)

## Shell Commands

    s <bookmark_name> - Saves the current directory as "bookmark_name"
    g <bookmark_name> - Goes (cd) to the directory associated with "bookmark_name"
    p <bookmark_name> - Prints the directory associated with "bookmark_name"
    d <bookmark_name> - Deletes the bookmark
    l                 - Lists all available bookmarks
    ll                - Interactive bookmark selector (requires fzf)
    
## Example Usage

    $ cd /var/www/
    $ s webfolder
    $ cd /usr/local/lib/
    $ s locallib
    $ l
    $ g web<tab>
    $ g webfolder

## Where Bashmarks are stored
    
All of your directory bookmarks are saved in a file called ".sdirs" in your HOME directory.


## Creators 

* [Huy Nguyen](https://github.com/huyng)
* [Karthick Gururaj](https://github.com/karthick-gururaj)
