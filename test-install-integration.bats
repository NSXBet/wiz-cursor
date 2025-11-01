#!/usr/bin/env bats
# Integration test for install.sh - verifies actual installation works

setup() {
    SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
}

teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

@test "install.sh installs successfully without version" {
    run bash "$SCRIPT_DIR/install.sh"
    [ "$status" -eq 0 ]
    
    # Verify .cursor directory was created
    [ -d ".cursor" ]
    [ -d ".cursor/agents" ]
    [ -d ".cursor/commands" ]
    
    # Verify Wiz files exist
    [ -n "$(find .cursor/agents -name 'wiz-*.md' 2>/dev/null)" ]
    [ -n "$(find .cursor/commands -name 'wiz-*.md' 2>/dev/null)" ]
}

@test "install.sh installs successfully with HEAD version" {
    run bash "$SCRIPT_DIR/install.sh" --version HEAD
    [ "$status" -eq 0 ]
    
    # Verify .cursor directory was created
    [ -d ".cursor" ]
    [ -d ".cursor/agents" ]
    [ -d ".cursor/commands" ]
}

@test "install.sh updates existing installation" {
    # First install
    bash "$SCRIPT_DIR/install.sh" --version HEAD > /dev/null 2>&1
    [ -d ".cursor" ]
    
    # Update
    run bash "$SCRIPT_DIR/install.sh" --version HEAD
    [ "$status" -eq 0 ]
    
    # Verify still installed
    [ -d ".cursor" ]
    [ -d ".cursor/agents" ]
    [ -d ".cursor/commands" ]
}

@test "install.sh works when piped to bash" {
    run bash -c "cat '$SCRIPT_DIR/install.sh' | bash"
    [ "$status" -eq 0 ]
    
    # Verify .cursor directory was created
    [ -d ".cursor" ]
    [ -d ".cursor/agents" ]
    [ -d ".cursor/commands" ]
}

