#!/usr/bin/env bash

set -euo pipefail

# ===== Constants & Colors =====
readonly C_RESET='\e[0m'
readonly C_INFO='\e[1;34m'
readonly C_SUCCESS='\e[1;32m'
readonly C_ERROR='\e[1;31m'
readonly C_WARN='\e[1;33m'

readonly VENV_PATH="./.venv"
readonly MIRROR_URL="mirror.unair.ac.id"
readonly REPO_TEMPLATE="./templates/sources.list"

REAL_USER=""

# ===== Logging =====
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

# ===== Stage Detection =====
get_real_user() {
    if [[ -n "${SUDO_USER:-}" ]]; then
        REAL_USER="$SUDO_USER"
    else
        REAL_USER="$(logname 2>/dev/null || true)"
    fi

    if [[ -z "$REAL_USER" || "$REAL_USER" == "root" ]]; then
        log error "Unable to determine non-root user."
        exit 1
    fi
}

# ===== Post-Sudo Reboot Prompt =====
prompt_reboot() {
    echo
    log warn "System reboot is required for sudo group changes to take effect."
    echo
    echo "After reboot:"
    echo "➔ Login as your normal user (NOT root)"
    echo "➔ Run this script again: sudo ./setup.sh"
    echo

    read -rp "Reboot now? [Y/n]: " choice

    case "${choice:-Y}" in
        Y|y|"")
            log info "Rebooting system..."
            /sbin/reboot
            ;;
        N|n)
            log warn "Please reboot manually before running the script again."
            exit 0
            ;;
        *)
            log warn "Invalid input. Please run the script again after reboot."
            exit 1
            ;;
    esac
}

# ===== Stage 1 → Elevate to root =====
ensure_root() {
    if [[ $EUID -ne 0 ]]; then
        log warn "Root privileges required."
        echo
        echo "➔ Please enter ROOT password to continue..."
        exec su -c "$0 $*"
    fi
}

# ===== Stage 2 =====
add_user_to_sudo() {
    if id -nG "$REAL_USER" | grep -qw sudo; then
        log info "$REAL_USER already in sudo group."
        return 1
    else
        log info "Adding $REAL_USER to sudo group..."

        echo "$REAL_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/wafley"
        /usr/sbin/usermod -aG sudo "$REAL_USER"
        chmod 0440 "/etc/sudoers.d/wafley"

        log success "User added to sudo group."
        return 0
    fi
}

configure_repositories() {
    [[ ! -f "$REPO_TEMPLATE" ]] && { log error "Missing template"; exit 1; }

    log info "Updating APT sources..."
    cp /etc/apt/sources.list /etc/apt/sources.list.bak 2>/dev/null || true
    cp "$REPO_TEMPLATE" /etc/apt/sources.list
    log success "Repositories configured."
}

check_network() {
    log info "Checking network..."
    ping -c 3 -W 2 "$MIRROR_URL" &>/dev/null || {
        log error "Network unreachable."
        exit 1
    }
    log success "Network OK."
}

bootstrap_packages() {
    log info "Installing base packages..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq sudo python3 python3-venv python3-pip git curl
    log success "Packages installed."
}

setup_python() {
    log info "Setting up Python environment..."

    if [[ ! -d "$VENV_PATH" ]]; then
        python3 -m venv "$VENV_PATH"
        chown -R "$REAL_USER":"$REAL_USER" "$VENV_PATH"
    fi

    if [[ ! -f "requirements.txt" ]]; then
        echo -e "rich\nPyYAML" > requirements.txt
        chown "$REAL_USER":"$REAL_USER" requirements.txt
    fi

    sudo -u "$REAL_USER" "$VENV_PATH/bin/pip" install -q --upgrade pip
    sudo -u "$REAL_USER" "$VENV_PATH/bin/pip" install -q -r requirements.txt

    log success "Python ready."
}

run_main() {
    local main_script="core/main.py"
    if [[ -f "$main_script" ]]; then
        log info "Running orchestrator..."
        sudo -u "$REAL_USER" "$VENV_PATH/bin/python" "$main_script"
    else
        log warn "No orchestrator found."
    fi
}

# ===== MAIN =====
main() {
    get_real_user
    ensure_root "$@"

    log info "Running as root for user: $REAL_USER"

    bootstrap_packages

    if add_user_to_sudo; then
        prompt_reboot
        exit 0
    fi

    configure_repositories
    check_network
    setup_python
    run_main

    log success "Bootstrap complete!"
}

main "$@"