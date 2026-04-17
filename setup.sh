#!/usr/bin/env bash

set -euo pipefail

# ===== Constants & Colors =====
readonly C_RESET='\e[0m'
readonly C_INFO='\e[1;34m'
readonly C_SUCCESS='\e[1;32m'
readonly C_ERROR='\e[1;31m'
readonly C_WARN='\e[1;33m'

readonly VENV_PATH="./.venv"
readonly SUDOERS_FILE="/etc/sudoers.d/99-automation-tool"
readonly MIRROR_URL="mirror.unair.ac.id"
readonly REPO_TEMPLATE="./templates/sources.list"

# Global variable for the non-root user
REAL_USER=""

# ===== Logging Functions =====
log() {
    local level="$1" message="$2" color="" label=""
    case "$level" in
        info)    color="$C_INFO";    label="INFO" ;;
        success) color="$C_SUCCESS"; label="SUCCESS" ;;
        warn)    color="$C_WARN";    label="WARN" ;;
        error)   color="$C_ERROR";   label="ERROR" ;;
    esac
    printf "%b[%-7s]%b %s\n" "$color" "$label" "$C_RESET" "$message"
}

# ===== Signal Handling =====
cleanup() {
    echo -e "\n${C_WARN}[!] Process interrupted. Cleaning up...${C_RESET}"
    exit 1
}
trap cleanup SIGINT SIGTERM

# ===== Helper Functions =====
# ? [Get current terminal user (non-root)]
get_real_user() {
    REAL_USER=${SUDO_USER:-$(id -nu 1000 2>/dev/null || echo "")}
    if [[ -z "$REAL_USER" ]]; then
        log error "Could not identify local user."
        exit 1
    fi
}

# ? [Wrapper for running commands as the real user]
as_user() {
    sudo -u "$REAL_USER" "$@"
}

# ===== Banner =====
print_banner() {
    local term_width
    local title subtitle author_plain
    local title_colored subtitle_colored author_display

    term_width=$(tput cols 2>/dev/null || echo 80)

    title="Debian 13 Automation Bootstrap"
    subtitle="Automate smarter, start faster"
    author_plain="Created by wafley"

    title_colored="${C_SUCCESS}${title}${C_RESET}"
    subtitle_colored="${C_INFO}${subtitle}${C_RESET}"
    author_display="${C_WARN}Created by \e]8;;https://github.com/wafley\a${C_SUCCESS}wafley${C_WARN}\e]8;;\a${C_RESET}"

    center_text() {
        local display_text="$1"
        local plain_text="$2"
        local padding=$(( (term_width - ${#plain_text}) / 2 ))
        printf "%*s%b\n" "$padding" "" "$display_text"
    }

    printf "${C_INFO}%*s${C_RESET}\n" "$term_width" '' | tr ' ' '═'

    center_text "$title_colored" "$title"
    center_text "$subtitle_colored" "$subtitle"
    center_text "$author_display" "$author_plain"

    printf "${C_INFO}%*s${C_RESET}\n\n" "$term_width" '' | tr ' ' '═'
}

# ===== Core Functions =====
# ? [Ensure script is executed with root privileges]
check_root_access() {
    log info "Validating system access..."
    if [[ $EUID -ne 0 ]]; then
        log error "Root privileges required."
        [[ ! -x "$(command -v sudo)" ]] && log warn "Log in as root: su -" || log warn "Run: sudo $0"
        exit 1
    fi
    log success "Root privileges verified."
}

# ? [Install sudo if not already available]
setup_sudo() {
    if ! command -v sudo &>/dev/null; then
        log warn "Installing sudo..."
        apt-get update -y -qq >/dev/null
        apt-get install -y -qq sudo &>/dev/null
    fi
}

# ? [Configure user to have sudo access and temporary passwordless execution]
configure_user_permissions() {
    if ! groups "$REAL_USER" | grep -q "\bsudo\b"; then
        log info "Granting sudo group to $REAL_USER..."
        usermod -aG sudo "$REAL_USER"
    fi

    log warn "Applying temporary NOPASSWD policy..."
    echo "$REAL_USER ALL=(ALL) NOPASSWD:ALL" > "$SUDOERS_FILE"
    chmod 0440 "$SUDOERS_FILE"
}

# ? [Replace default APT repositories using predefined mirror template]
configure_repositories() {
    [[ ! -f "$REPO_TEMPLATE" ]] && { log error "Template missing: $REPO_TEMPLATE"; exit 1; }
    
    log info "Updating sources.list via UNAIR mirror..."
    [[ ! -f "/etc/apt/sources.list.bak" ]] && cp /etc/apt/sources.list /etc/apt/sources.list.bak
    
    cp "$REPO_TEMPLATE" /etc/apt/sources.list
    log success "Repositories configured."
}

# ? [Verify network connectivity to the selected mirror]
check_network() {
    log info "Testing network ($MIRROR_URL)..."
    ping -c 3 -W 2 "$MIRROR_URL" &>/dev/null || { log error "Network unstable."; exit 1; }
    log success "Network online."
}

# ? [Install required base packages (Python, pip, git, curl)]
bootstrap_environment() {
    log info "Installing Python & Git..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y -qq >/dev/null
    apt-get install -y -qq python3 python3-venv python3-pip curl git &>/dev/null
}

# ? [Prepare Python virtual environment and install dependencies]
setup_python_orchestrator() {
    log info "Setting up Venv..."
    [[ ! -d "$VENV_PATH" ]] && { python3 -m venv "$VENV_PATH"; chown -R "$REAL_USER":"$REAL_USER" "$VENV_PATH"; }

    if [[ ! -f "requirements.txt" ]]; then
        log warn "Generating default requirements.txt..."
        echo -e "rich==13.7.0\nPyYAML==6.0.1" > requirements.txt
        chown "$REAL_USER":"$REAL_USER" requirements.txt
    fi

    log info "Installing dependencies as $REAL_USER..."
    as_user "$VENV_PATH/bin/pip" install -q --upgrade pip
    as_user "$VENV_PATH/bin/pip" install -q -r requirements.txt
    log success "Python environment ready."
}

# ? [Execute main Python orchestrator script]
run_python_main() {
    local main_script="core/main.py"
    if [[ -f "$main_script" ]]; then
        log info "Launching Orchestrator..."
        as_user "$VENV_PATH/bin/python" "$main_script"
    else
        log error "Missing: $main_script"
        exit 1
    fi
}

# ? [Remove temporary sudo privileges for security cleanup]
cleanup_permissions() {
    [[ -f "$SUDOERS_FILE" ]] && { rm -f "$SUDOERS_FILE"; log success "Security policy restored."; }
}

# ===== Main Execution =====
main() {
    clear
    print_banner
    
    get_real_user
    check_root_access
    setup_sudo
    configure_user_permissions
    configure_repositories
    check_network
    bootstrap_environment
    setup_python_orchestrator

    # Run Orchestrator
    run_python_main

    # Policy revoked after Python finishes
    cleanup_permissions
}

main "$@"