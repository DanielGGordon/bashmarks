# Copyright (c) 2010, Huy Nguyen, http://www.huyng.com
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided
# that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright notice, this list of conditions
#       and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
#       following disclaimer in the documentation and/or other materials provided with the distribution.
#     * Neither the name of Huy Nguyen nor the names of contributors
#       may be used to endorse or promote products derived from this software without
#       specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.


# USAGE:
# s bookmarkname - saves the curr dir as bookmarkname
# g bookmarkname - jumps to the that bookmark
# g b[TAB] - tab completion is available
# p bookmarkname - prints the bookmark
# p b[TAB] - tab completion is available
# d bookmarkname - deletes the bookmark
# d [TAB] - tab completion is available
# l - list all bookmarks
# ll - interactive bookmark selector (fzf)

# setup file to store bookmarks
if [ ! -n "$SDIRS" ]; then
    SDIRS=~/.sdirs
fi
touch "$SDIRS"

RED="0;31m"
GREEN="0;33m"

# in-memory bookmark store
declare -gA _bookmarks

# load bookmarks from file into associative array
function _bookmarks_load {
    _bookmarks=()
    if [ -s "$SDIRS" ]; then
        local name path
        while IFS= read -r line; do
            # parse lines like: export DIR_name="path"
            if [[ "$line" =~ ^export\ DIR_([A-Za-z0-9_]+)=\"(.*)\"$ ]]; then
                _bookmarks["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
            fi
        done < "$SDIRS"
    fi
}

# write associative array back to file
function _bookmarks_save {
    local name
    : > "$SDIRS"
    for name in $(printf '%s\n' "${!_bookmarks[@]}" | sort); do
        echo "export DIR_${name}=\"${_bookmarks[$name]}\"" >> "$SDIRS"
    done
}

# resolve a stored path (expand $HOME)
function _bookmarks_resolve {
    eval echo "$1"
}

# load bookmarks on source
_bookmarks_load

# save current directory to bookmarks
function s {
    check_help $1
    _bookmark_name_valid "$@"
    if [ -z "$exit_message" ]; then
        local curdir="${PWD/#$HOME/\$HOME}"
        _bookmarks["$1"]="$curdir"
        _bookmarks_save
    fi
}

# jump to bookmark
function g {
    check_help $1
    local raw="${_bookmarks[$1]}"
    if [ -z "$raw" ]; then
        echo -e "\033[${RED}WARNING: '${1}' bashmark does not exist\033[00m"
        return 1
    fi
    local target
    target="$(_bookmarks_resolve "$raw")"
    if [ -d "$target" ]; then
        cd "$target"
    else
        echo -e "\033[${RED}WARNING: '${target}' does not exist\033[00m"
    fi
}

# print bookmark
function p {
    check_help $1
    local raw="${_bookmarks[$1]}"
    if [ -n "$raw" ]; then
        _bookmarks_resolve "$raw"
    fi
}

# delete bookmark
function d {
    check_help $1
    _bookmark_name_valid "$@"
    if [ -z "$exit_message" ]; then
        unset '_bookmarks[$1]'
        _bookmarks_save
    fi
}

# print out help for the forgetful
function check_help {
    if [ "$1" = "-h" ] || [ "$1" = "-help" ] || [ "$1" = "--help" ] ; then
        echo ''
        echo 's <bookmark_name> - Saves the current directory as "bookmark_name"'
        echo 'g <bookmark_name> - Goes (cd) to the directory associated with "bookmark_name"'
        echo 'p <bookmark_name> - Prints the directory associated with "bookmark_name"'
        echo 'd <bookmark_name> - Deletes the bookmark'
        echo 'l                 - Lists all available bookmarks'
        echo 'll                - Interactive bookmark selector (fzf)'
        kill -SIGINT $$
    fi
}

# list bookmarks with dirname
function l {
    check_help $1
    local name
    for name in $(printf '%s\n' "${!_bookmarks[@]}" | sort); do
        printf "\033[0;33m%-20s\033[0m %s\n" "$name" "${_bookmarks[$name]}"
    done
}

# interactive bookmark selector using fzf
function ll {
    check_help $1
    local selected name
    selected=$(
        for name in $(printf '%s\n' "${!_bookmarks[@]}" | sort); do
            printf "%s\t%s\n" "$name" "$(_bookmarks_resolve "${_bookmarks[$name]}")"
        done \
        | fzf --height=40% --reverse --prompt="bookmark> " --no-multi \
              --delimiter='\t' --with-nth=1 \
              --preview='dir="$(echo {} | cut -f2)"; echo "$dir"; echo "---"; ls -p --color=always --group-directories-first "$dir" 2>/dev/null | head -20 || echo "directory not found"' \
              --preview-window=right:40% \
        | cut -f2
    )
    if [ -n "$selected" ]; then
        if [ -d "$selected" ]; then
            cd "$selected"
        else
            echo -e "\033[${RED}WARNING: '${selected}' does not exist\033[00m"
        fi
    fi
}

# list bookmark names only (for completion)
function _l {
    printf '%s\n' "${!_bookmarks[@]}" | sort
}

# validate bookmark name
function _bookmark_name_valid {
    exit_message=""
    if [ -z $1 ]; then
        exit_message="bookmark name required"
        echo $exit_message
    elif [ "$1" != "$(echo $1 | sed 's/[^A-Za-z0-9_]//g')" ]; then
        exit_message="bookmark name is not valid"
        echo $exit_message
    fi
}

# completion command
function _comp {
    local curw
    COMPREPLY=()
    curw=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=($(compgen -W '`_l`' -- $curw))
    return 0
}

# ZSH completion command
function _compzsh {
    reply=($(_l))
}

# bind completion command for g,p,d to _comp
if [ $ZSH_VERSION ]; then
    compctl -K _compzsh g
    compctl -K _compzsh p
    compctl -K _compzsh d
else
    shopt -s progcomp
    complete -F _comp g
    complete -F _comp p
    complete -F _comp d
fi
