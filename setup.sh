#!/usr/bin/env bash

# ==============================================================================
# DEBIAN 13 (TRIXIE) BOOTSTRAPPER
# Description: Prepares the base environment for the Python automation engine.
# ==============================================================================

set -euo pipefail

# Constants & Colors
readonly C_RESET='\e[0m'
readonly C_INFO='\e[1;34m'
readonly C_SUCCESS='\e[1;32m'
readonly C_ERROR='\e[1;31m'
readonly C_WARN='\e[1;33m'

readonly VENV_PATH="./.venv"
readonly SUDOERS_FILE="/etc/sudoers.d/99-automation-tool"
readonly MIRROR_URL="mirror.unair.ac.id"

# Logging Functions
log_info()    { echo -e "${C_INFO}[INFO]${C_RESET}    $1"; }
log_success() { echo -e "${C_SUCCESS}[SUCCESS]${C_RESET} $1"; }
log_error()   { echo -e "${C_ERROR}[ERROR]${C_RESET}   $1"; }
log_warn()    { echo -e "${C_WARN}[WARN]${C_RESET}    $1"; }

# Signal Handling
cleanup() {
    echo -e "\n${C_WARN}[!] Process interrupted. Cleaning up...${C_RESET}"
    exit 1
}
trap cleanup SIGINT SIGTERM

# Core Functions

check_root_access() {
    log_info "Validating system access..."
    if [[ $EUID -ne 0 ]]; then
        log_error "Access denied. Root privileges are required."
        if ! command -v sudo &> /dev/null; then
            echo -e "\n${C_WARN}Instruction:${C_RESET}"
            echo -e "Your system lacks 'sudo'. Log in as root using: ${C_INFO}su -${C_RESET}"
        else
            echo -e "\n${C_WARN}Instruction:${C_RESET}"
            echo -e "Please run with: ${C_INFO}sudo $0${C_RESET}"
        fi
        exit 1
    fi
    log_success "Root privileges verified."
}

setup_sudo() {
    if ! command -v sudo &> /dev/null; then
        log_warn "'sudo' not found. Installing automatically..."
        apt-get update -y -qq > /dev/null
        apt-get install -y -qq sudo &> /dev/null
        log_success "The 'sudo' package has been installed."
    fi
}

configure_user_permissions() {
    local REAL_USER
    REAL_USER=${SUDO_USER:-$(id -nu 1000 2>/dev/null || echo "")}

    if [[ -z "$REAL_USER" ]]; then
        log_warn "Could not identify local user. Skipping sudoers config."
        return
    fi

    # Add to sudo group
    if ! groups "$REAL_USER" | grep &>/dev/null "\bsudo\b"; then
        log_info "Adding user '$REAL_USER' to sudo group..."
        usermod -aG sudo "$REAL_USER"
        log_success "User '$REAL_USER' added to sudo group."
    fi

    # Apply NOPASSWD for seamless automation
    if [ ! -f "$SUDOERS_FILE" ]; then
        log_info "Applying NOPASSWD policy for '$REAL_USER'..."
        echo "$REAL_USER ALL=(ALL) NOPASSWD:ALL" > "$SUDOERS_FILE"
        chmod 0440 "$SUDOERS_FILE"
        log_success "Sudoers policy applied."
    fi
}

# Main Execution
main() {
    clear
    echo -e "${C_WARN}==========================================${C_RESET}"
    echo -e "${C_SUCCESS}   DEBIAN 13 AUTOMATION TOOL: BOOTSTRAP    ${C_RESET}"
    echo -e "${C_WARN}==========================================${C_RESET}\n"

    check_root_access
    setup_sudo
    configure_user_permissions
}

main "$@"