#!/usr/bin/env bats
# Test suite for install.sh using bats-core

setup() {
    # Get the directory where install.sh is located
    SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"

    # Source the install script functions (without running main)
    # This works because install.sh only runs main() when executed directly
    source "$SCRIPT_DIR/install.sh"
}

# Test: extract_github_info
@test "extract_github_info with https URL" {
    run extract_github_info "https://github.com/NSXBet/wiz-cursor.git"
    [ "$status" -eq 0 ]
    [ "$output" = "NSXBet wiz-cursor" ]
}

@test "extract_github_info with ssh URL" {
    run extract_github_info "git@github.com:user/repo.git"
    [ "$status" -eq 0 ]
    [ "$output" = "user repo" ]
}

@test "extract_github_info with invalid URL should fail" {
    run extract_github_info "not-a-github-url"
    [ "$status" -ne 0 ]
}

# Test: build_tarball_urls
@test "build_tarball_urls for tag should include refs/tags" {
    run build_tarball_urls "owner" "repo" "tag" "v1.0.0"
    [ "$status" -eq 0 ]
    [[ $output == *"refs/tags/v1.0.0"* ]]
}

@test "build_tarball_urls for tag should include archive URL" {
    run build_tarball_urls "owner" "repo" "tag" "v1.0.0"
    [ "$status" -eq 0 ]
    [[ $output == *"archive/v1.0.0.tar.gz"* ]]
}

@test "build_tarball_urls for branch should include refs/heads" {
    run build_tarball_urls "owner" "repo" "branch" "main"
    [ "$status" -eq 0 ]
    [[ $output == *"refs/heads/main"* ]]
}

@test "build_tarball_urls for branch should include archive URL" {
    run build_tarball_urls "owner" "repo" "branch" "main"
    [ "$status" -eq 0 ]
    [[ $output == *"archive/main.tar.gz"* ]]
}

# Test: determine_version
@test "determine_version with no arg should fetch latest" {
    # Mock fetch_latest_release
    fetch_latest_release() {
        echo "v0.1.0"
    }

    determine_version ""
    [ "$VERSION" = "v0.1.0" ]
    [ "$REF" = "v0.1.0" ]
    [ "$REF_TYPE" = "tag" ]
}

@test "determine_version with HEAD should use HEAD" {
    determine_version "HEAD"
    [ "$VERSION" = "HEAD" ]
    [ "$REF" = "main" ]
    [ "$REF_TYPE" = "branch" ]
}

@test "determine_version with specific version" {
    determine_version "v0.2.0"
    [ "$VERSION" = "v0.2.0" ]
    [ "$REF" = "v0.2.0" ]
    [ "$REF_TYPE" = "tag" ]
}

# Test: check_wiz_installed
@test "check_wiz_installed with no .cursor dir" {
    local test_dir
    test_dir=$(mktemp -d)
    cd "$test_dir"

    check_wiz_installed
    [ "$WIZ_INSTALLED" = "false" ]

    rm -rf "$test_dir"
}

@test "check_wiz_installed with .cursor but no wiz files" {
    local test_dir
    test_dir=$(mktemp -d)
    cd "$test_dir"
    mkdir -p .cursor/agents .cursor/commands

    check_wiz_installed
    [ "$WIZ_INSTALLED" = "false" ]

    rm -rf "$test_dir"
}

@test "check_wiz_installed with wiz files" {
    local test_dir
    test_dir=$(mktemp -d)
    cd "$test_dir"
    mkdir -p .cursor/agents .cursor/commands
    touch .cursor/agents/wiz-test.md

    check_wiz_installed
    [ "$WIZ_INSTALLED" = "true" ]

    rm -rf "$test_dir"
}

# Test: copy_cursor_files
@test "copy_cursor_files should create agents and commands dirs" {
    local test_dir
    test_dir=$(mktemp -d)
    local source_dir="$test_dir/source"
    local dest_dir="$test_dir/dest"

    mkdir -p "$source_dir/agents" "$source_dir/commands"
    echo "test" >"$source_dir/agents/test.md"
    echo "test" >"$source_dir/commands/test.md"

    run copy_cursor_files "$source_dir" "$dest_dir"
    [ "$status" -eq 0 ]
    [ -d "$dest_dir/agents" ]
    [ -d "$dest_dir/commands" ]
    [ -f "$dest_dir/agents/test.md" ]
    [ -f "$dest_dir/commands/test.md" ]

    rm -rf "$test_dir"
}

@test "copy_cursor_files should fail with non-existent source" {
    local test_dir
    test_dir=$(mktemp -d)
    local dest_dir="$test_dir/dest"

    run copy_cursor_files "$test_dir/nonexistent" "$dest_dir"
    [ "$status" -ne 0 ]

    rm -rf "$test_dir"
}

# Test: parse_args
@test "parse_args with --version flag" {
    parse_args --version "v1.0.0"
    [ "$VERSION" = "v1.0.0" ]
    VERSION=""
}

@test "parse_args with --version= syntax" {
    parse_args --version=v2.0.0
    [ "$VERSION" = "v2.0.0" ]
    VERSION=""
}

@test "parse_args with HEAD" {
    parse_args --version HEAD
    [ "$VERSION" = "HEAD" ]
    VERSION=""
}
