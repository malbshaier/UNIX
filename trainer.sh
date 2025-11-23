#!/bin/bash

set -euo pipefail

# Script name and directories
SCRIPT_NAME="trainer.sh"
PRACTICE_DIR_BASE="practice_level"
STATE_FILE=".trainer_state"
DEFAULT_LEVELS=4

# Color support
if command -v tput >/dev/null && [ -t 1 ]; then
    GREEN=$(tput setaf 2)
    RED=$(tput setaf 1)
    YELLOW=$(tput setaf 3)
    RESET=$(tput sgr0)
else
    GREEN=""
    RED=""
    YELLOW=""
    RESET=""
fi

# Usage help function
usage() {
    cat << EOF
Usage: ./$SCRIPT_NAME <subcommand> [level]

Unix Permissions Trainer - A Bash script for practicing Unix file permissions.

Subcommands:
  new       Start a new level (creates practice folder and sets up files)
  check     Check your changes against the level goal
  reset     Reset the current level to initial state
  clean     Clean up all practice folders and state
  help      Show this help message

Levels: 1 to $DEFAULT_LEVELS (specify after subcommand, e.g., ./$SCRIPT_NAME new 1)

Examples:
  ./$SCRIPT_NAME new 1       # Start Level 1
  chmod g+r,o-w notes.txt    # Make changes
  ./$SCRIPT_NAME check 1     # Check progress
  ./$SCRIPT_NAME reset 1     # Reset Level 1
  ./$SCRIPT_NAME clean       # Remove all

Note: This tool targets Linux (GNU stat). macOS stat differs and is not supported.
EOF
    exit 0
}

# Function to get current score
get_score() {
    if [ -f "$STATE_FILE" ]; then
        attempts=$(grep "attempts" "$STATE_FILE" | cut -d= -f2)
        passes=$(grep "passes" "$STATE_FILE" | cut -d= -f2)
    else
        attempts=0
        passes=0
    fi
    echo "Score: $passes passes out of $attempts attempts"
}

# Update score
update_score() {
    local result="$1"
    if [ ! -f "$STATE_FILE" ]; then
        echo "attempts=0" > "$STATE_FILE"
        echo "passes=0" >> "$STATE_FILE"
    fi
    attempts=$(grep "attempts" "$STATE_FILE" | cut -d= -f2)
    passes=$(grep "passes" "$STATE_FILE" | cut -d= -f2)
    attempts=$((attempts + 1))
    if [ "$result" = "pass" ]; then
        passes=$((passes + 1))
    fi
    sed -i "s/attempts=.*/attempts=$attempts/" "$STATE_FILE"
    sed -i "s/passes=.*/passes=$passes/" "$STATE_FILE"
}

# Level setup functions
setup_level1() {
    local dir="$1"
    mkdir -p "$dir"
    touch "$dir/notes.txt"
    chmod 777 "$dir/notes.txt"  # Initial: all permissions
    chown "$USER:$USER" "$dir/notes.txt"
    echo "Level 1 Goal: Make notes.txt readable by group (g+r), remove write from others (o-w). Target mode: 640"
    echo "Hint: Use chmod (octal or symbolic) on $dir/notes.txt"
}

check_level1() {
    local dir="$1"
    local file="$dir/notes.txt"
    if [ ! -f "$file" ]; then
        echo "${RED}Fail: File $file missing.${RESET}"
        return 1
    fi
    local mode=$(stat -c '%a' "$file")
    local owner=$(stat -c '%U' "$file")
    local group=$(stat -c '%G' "$file")
    if [ "$mode" = "640" ] && [ "$owner" = "$USER" ] && [ "$group" = "$USER" ]; then
        echo "${GREEN}Pass! Mode is correct.${RESET}"
        return 0
    else
        echo "${RED}Fail.${RESET}"
        if [ "$mode" != "640" ]; then
            echo "${YELLOW}Hint: Mode should be 640 (rw-r-----). Current: $mode${RESET}"
            hint_bits "$mode" "640"
        fi
        if [ "$owner" != "$USER" ] || [ "$group" != "$USER" ]; then
            echo "${YELLOW}Hint: Owner/group should be $USER:$USER. Current: $owner:$group${RESET}"
        fi
        return 1
    fi
}

setup_level2() {
    local dir="$1"
    mkdir -p "$dir/subdir"
    touch "$dir/subdir/script.sh"
    chmod 755 "$dir/subdir"
    chmod 644 "$dir/subdir/script.sh"
    chown "$USER:$USER" "$dir/subdir" "$dir/subdir/script.sh"
    echo "Level 2 Goal: Make subdir executable by owner/group (u+x,g+x), script.sh executable by all (a+x). Target: dir 775, file 755"
    echo "Hint: Directories need execute for access. Use chmod on $dir/subdir and $dir/subdir/script.sh"
}

check_level2() {
    local dir="$1"
    local d="$dir/subdir"
    local f="$dir/subdir/script.sh"
    if [ ! -d "$d" ] || [ ! -f "$f" ]; then
        echo "${RED}Fail: Directory or file missing.${RESET}"
        return 1
    fi
    local dmode=$(stat -c '%a' "$d")
    local fmode=$(stat -c '%a' "$f")
    if [ "$dmode" = "775" ] && [ "$fmode" = "755" ]; then
        echo "${GREEN}Pass! Modes correct.${RESET}"
        return 0
    else
        echo "${RED}Fail.${RESET}"
        if [ "$dmode" != "775" ]; then
            echo "${YELLOW}Hint: Directory should be 775 (rwxrwxr-x). Current: $dmode${RESET}"
            hint_bits "$dmode" "775"
        fi
        if [ "$fmode" != "755" ]; then
            echo "${YELLOW}Hint: File should be 755 (rwxr-xr-x). Current: $fmode${RESET}"
            hint_bits "$fmode" "755"
        fi
        return 1
    fi
}

setup_level3() {
    local dir="$1"
    mkdir -p "$dir"
    touch "$dir/config.conf"
    chmod 600 "$dir/config.conf"  # Initial: owner rw only
    chown "$USER:$USER" "$dir/config.conf"
    echo "Level 3 Goal: Mix modes - Make config.conf group writable (g+w), others readable (o+r). Target: 646"
    echo "Hint: Use symbolic (e.g., chmod g+w,o+r) or octal on $dir/config.conf"
}

check_level3() {
    local dir="$1"
    local file="$dir/config.conf"
    if [ ! -f "$file" ]; then
        echo "${RED}Fail: File missing.${RESET}"
        return 1
    fi
    local mode=$(stat -c '%a' "$file")
    if [ "$mode" = "646" ]; then
        echo "${GREEN}Pass! Mode correct.${RESET}"
        return 0
    else
        echo "${RED}Fail.${RESET}"
        echo "${YELLOW}Hint: Should be 646 (rw-r--rw-). Current: $mode${RESET}"
        hint_bits "$mode" "646"
        return 1
    fi
}

setup_level4() {
    local dir="$1"
    mkdir -p "$dir"
    umask 000  # Temp to create with full perms
    touch "$dir/newfile.txt"
    umask 022  # Reset default
    echo "Level 4 Goal: Set umask to 027, create a new file 'protected.txt' in $dir, target mode 640"
    echo "Hint: Use umask 027, then touch $dir/protected.txt. Check will verify its mode."
}

check_level4() {
    local dir="$1"
    local file="$dir/protected.txt"
    if [ ! -f "$file" ]; then
        echo "${RED}Fail: Create protected.txt after setting umask.${RESET}"
        return 1
    fi
    local mode=$(stat -c '%a' "$file")
    if [ "$mode" = "640" ]; then
        echo "${GREEN}Pass! Umask applied correctly.${RESET}"
        return 0
    else
        echo "${RED}Fail.${RESET}"
        echo "${YELLOW}Hint: With umask 027, new files should be 640 (rw-r-----). Current: $mode${RESET}"
        hint_bits "$mode" "640"
        return 1
    fi
}

# Hint function for wrong bits
hint_bits() {
    local current="$1"
    local target="$2"
    local bits=("---" "--x" "-w-" "-wx" "r--" "r-x" "rw-" "rwx")
    echo "${YELLOW}Bit differences:${RESET}"
    for i in {0..2}; do
        c_bit=${current:$i:1}
        t_bit=${target:$i:1}
        if [ "$c_bit" != "$t_bit" ]; then
            case $i in
                0) user="Owner" ;;
                1) user="Group" ;;
                2) user="Others" ;;
            esac
            echo "${YELLOW}$user bit wrong: Expected ${bits[$t_bit]}, got ${bits[$c_bit]}${RESET}"
        fi
    done
}

# Validate level
validate_level() {
    local level="$1"
    if ! [[ "$level" =~ ^[1-4]$ ]]; then
        echo "Error: Level must be 1 to $DEFAULT_LEVELS" >&2
        exit 1
    fi
}

# Main logic
if [ $# -lt 1 ] || [ "$1" = "help" ] || [ "$1" = "--help" ]; then
    usage
fi

subcommand="$1"
shift

case "$subcommand" in
    new|check|reset)
        if [ $# -ne 1 ]; then
            echo "Error: Specify level (e.g., $subcommand 1)" >&2
            exit 1
        fi
        level="$1"
        validate_level "$level"
        practice_dir="${PRACTICE_DIR_BASE}${level}"
        ;;
    clean)
        ;;
    *)
        echo "Error: Unknown subcommand '$subcommand'" >&2
        usage
        ;;
esac

case "$subcommand" in
    new)
        if [ -d "$practice_dir" ]; then
            rm -rf "$practice_dir"
        fi
        setup_level${level} "$practice_dir"
        ;;

    check)
        if [ ! -d "$practice_dir" ]; then
            echo "Error: Start level with 'new $level' first" >&2
            exit 1
        fi
        if check_level${level} "$practice_dir"; then
            update_score "pass"
        else
            update_score "fail"
        fi
        get_score
        ;;

    reset)
        if [ -d "$practice_dir" ]; then
            rm -rf "$practice_dir"
        fi
        setup_level${level} "$practice_dir"
        echo "Level $level reset."
        ;;

    clean)
        for i in {1..4}; do
            rm -rf "${PRACTICE_DIR_BASE}${i}"
        done
        rm -f "$STATE_FILE"
        echo "All practice areas and state cleaned."
        ;;
esac