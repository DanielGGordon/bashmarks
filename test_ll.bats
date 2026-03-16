#!/usr/bin/env bats

setup() {
    export SDIRS="$(mktemp)"
    export TEST_TARGET="$(mktemp -d)"
    export FAKE_FZF_DIR="$(mktemp -d)"
    export ORIG_PATH="$PATH"
    source "$BATS_TEST_DIRNAME/bashmarks.sh"
}

teardown() {
    rm -f "$SDIRS"
    rm -rf "$TEST_TARGET"
    rm -rf "$FAKE_FZF_DIR"
    export PATH="$ORIG_PATH"
}

add_bookmark() {
    echo "export DIR_${1}=\"${2}\"" >> "$SDIRS"
    _bookmarks_load
}

stub_fzf() {
    local output="$1"
    local exit_code="${2:-0}"
    cat > "$FAKE_FZF_DIR/fzf" <<SCRIPT
#!/bin/bash
if [ "$exit_code" -ne 0 ]; then
    exit $exit_code
fi
echo "$output"
SCRIPT
    chmod +x "$FAKE_FZF_DIR/fzf"
    export PATH="$FAKE_FZF_DIR:$ORIG_PATH"
}

# --- core command tests ---

@test "s saves a bookmark and persists to file" {
    cd "$TEST_TARGET"
    s testmark
    grep -q "DIR_testmark=" "$SDIRS"
}

@test "g jumps to a bookmarked directory" {
    add_bookmark "mydir" "$TEST_TARGET"
    g mydir
    [ "$PWD" = "$TEST_TARGET" ]
}

@test "g warns on nonexistent bookmark" {
    local output
    output=$(g nosuchmark 2>&1) || true
    [[ "$output" == *"does not exist"* ]]
}

@test "p prints the resolved path" {
    add_bookmark "mydir" "$TEST_TARGET"
    local output
    output=$(p mydir)
    [ "$output" = "$TEST_TARGET" ]
}

@test "d deletes a bookmark" {
    add_bookmark "mydir" "$TEST_TARGET"
    d mydir
    [ -z "${_bookmarks[mydir]}" ]
    ! grep -q "DIR_mydir=" "$SDIRS"
}

@test "l lists bookmarks" {
    add_bookmark "alpha" "/tmp/a"
    add_bookmark "beta" "/tmp/b"
    local output
    output=$(l)
    [[ "$output" == *"alpha"* ]]
    [[ "$output" == *"beta"* ]]
}

@test "_bookmarks_load round-trips with _bookmarks_save" {
    _bookmarks=()
    _bookmarks[foo]="/tmp/foo"
    _bookmarks[bar]="\$HOME/bar"
    _bookmarks_save
    _bookmarks=()
    _bookmarks_load
    [ "${_bookmarks[foo]}" = "/tmp/foo" ]
    [ "${_bookmarks[bar]}" = "\$HOME/bar" ]
}

# --- ll tests ---

@test "ll function exists after sourcing bashmarks" {
    [ "$(type -t ll)" = "function" ]
}

@test "ll with no bookmarks produces no error" {
    stub_fzf "" 130
    ll 2>/dev/null || true
}

@test "ll with fzf returning empty (Escape) does nothing" {
    add_bookmark "test" "$TEST_TARGET"
    stub_fzf "" 130
    local before="$PWD"
    ll 2>/dev/null || true
    [ "$PWD" = "$before" ]
}

@test "ll with fzf selecting a bookmark jumps to the right dir" {
    add_bookmark "mymark" "$TEST_TARGET"
    stub_fzf "mymark	$TEST_TARGET"
    ll
    [ "$PWD" = "$TEST_TARGET" ]
}

@test "ll resolves \$HOME paths correctly" {
    add_bookmark "homemark" "\$HOME"
    stub_fzf "homemark	$HOME"
    ll
    [ "$PWD" = "$HOME" ]
}

@test "ll warns when target directory does not exist" {
    local nonexistent="/tmp/bashmarks_nonexistent_$$"
    add_bookmark "gone" "$nonexistent"
    stub_fzf "gone	$nonexistent"
    local output
    output=$(ll 2>&1)
    [[ "$output" == *"WARNING"* ]]
    [[ "$output" == *"does not exist"* ]]
}
