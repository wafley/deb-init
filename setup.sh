#!/usr/bin/env bash

# ==============================================================================
# DEBIAN 13 (TRIXIE) BOOTSTRAPPER
# Description: Prepares the base environment for the Python automation engine.
# ==============================================================================

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

# ===== Logging Functions =====
log() {
    local level="$1"
    local message="$2"

    local color=""
    local label=""

    case "$level" in
        info)
            color="$C_INFO"
            label="INFO"
            ;;
        success)
            color="$C_SUCCESS"
            label="SUCCESS"
            ;;
        warn)
            color="$C_WARN"
            label="WARN"
            ;;
        error)
            color="$C_ERROR"
            label="ERROR"
            ;;
        *)
            color="$C_RESET"
            label="LOG"
            ;;
    esac

    printf "%b[%-7s]%b %s\n" "$color" "$label" "$C_RESET" "$message"
}

# ===== Signal Handling =====
cleanup() {
    echo -e "\n${C_WARN}[!] Process interrupted. Cleaning up...${C_RESET}"
    exit 1
}
trap cleanup SIGINT SIGTERM

# ===== Banner =====
print_banner() {
    local term_width
    term_width=$(tput cols 2>/dev/null || echo 80)

    local title="Debian 13 Automation Bootstrap"
    local subtitle="Automate smarter, start faster"

    local author_plain="Created by wafley"
    local author_display="Created by \e]8;;https://github.com/wafley\a${C_SUCCESS}wafley${C_WARN}\e]8;;\a"

    # Function center
    center_text() {
        local text="$1"
        local plain="$2"
        local padding=$(( (term_width - ${#plain}) / 2 ))
        printf "%*s%b\n" "$padding" "" "$text"
    }

    # Top border
    printf "${C_INFO}"
    printf '%*s\n' "$term_width" '' | tr ' ' '═'
    printf "${C_RESET}"

    # Content
    printf "${C_SUCCESS}"
    center_text "$title" "$title"

    printf "${C_INFO}"
    center_text "$subtitle" "$subtitle"

    printf "${C_WARN}"
    center_text "$author_display" "$author_plain"
    printf "${C_RESET}"

    # Bottom border
    printf "${C_INFO}"
    printf '%*s\n\n' "$term_width" '' | tr ' ' '═'
    printf "${C_RESET}"
}

# ===== Core Functions =====
# ? [Ensures the script is executed with root privileges]
check_root_access() {
    log info "Validating system access..."
    if [[ $EUID -ne 0 ]]; then
        log error "Access denied. Root privileges are required."
        if ! command -v sudo &> /dev/null; then
            echo -e "\n${C_WARN}Instruction:${C_RESET}"
            echo -e "Your system lacks 'sudo'. Log in as root using: ${C_INFO}su -${C_RESET}"
        else
            echo -e "\n${C_WARN}Instruction:${C_RESET}"
            echo -e "Please run with: ${C_INFO}sudo $0${C_RESET}"
        fi
        exit 1
    fi
    log success "Root privileges verified."
}

# ? [Ensures the script is executed with root privileges]
setup_sudo() {
    if ! command -v sudo &> /dev/null; then
        log_warn "'sudo' not found. Installing automatically..."
        apt-get update -y -qq > /dev/null
        apt-get install -y -qq sudo &> /dev/null
        log success "The 'sudo' package has been installed."
    fi
}

# ? [Configures user permissions and enables passwordless sudo for automation]
configure_user_permissions() {
    local REAL_USER
    REAL_USER=${SUDO_USER:-$(id -nu 1000 2>/dev/null || echo "")}

    if [[ -z "$REAL_USER" ]]; then
        log_warn "Could not identify local user. Skipping sudoers config."
        return
    fi

    # Add to sudo group
    if ! groups "$REAL_USER" | grep &>/dev/null "\bsudo\b"; then
        log info "Adding user '$REAL_USER' to sudo group..."
        usermod -aG sudo "$REAL_USER"
        log success "User '$REAL_USER' added to sudo group."
    fi

    # Apply NOPASSWD for seamless automation
    if [ ! -f "$SUDOERS_FILE" ]; then
        log info "Applying NOPASSWD policy for '$REAL_USER'..."
        echo "$REAL_USER ALL=(ALL) NOPASSWD:ALL" > "$SUDOERS_FILE"
        chmod 0440 "$SUDOERS_FILE"
        log success "Sudoers policy applied."
    fi
}

# Path to repository template file
readonly REPO_TEMPLATE="./templates/sources.list"
# ? [Replaces system repositories using predefined template]
configure_repositories() {
    log info "Configuring Debian Trixie repositories from template..."

    # Check if template exists
    if [ ! -f "$REPO_TEMPLATE" ]; then
        log error "Repository template not found at $REPO_TEMPLATE!"
        exit 1
    fi

    # Backup original sources.list
    if [ ! -f "/etc/apt/sources.list.bak" ]; then
        cp /etc/apt/sources.list /etc/apt/sources.list.bak
        log success "Backup created: /etc/apt/sources.list.bak"
    fi

    # Deploy template
    cp "$REPO_TEMPLATE" /etc/apt/sources.list
    log success "Repositories configured using UNAIR mirror."
}

# ? [Checks connectivity to the configured Debian mirror]
check_network() {
    log info "Verifying network connection to $MIRROR_URL..."
    
    # Check if mirror is reachable (3 attempts for stability check)
    if ! ping -c 3 -W 2 "$MIRROR_URL" &> /dev/null; then
        log error "Network unreachable or mirror is down. Please check your internet connection."
        exit 1
    fi
    log success "Network connection is stable."
}

# ? [Installs essential system packages required for the automation tool]
bootstrap_environment() {
    log info "Updating package index and installing core dependencies..."
    
    export DEBIAN_FRONTEND=noninteractive
    
    # Using -qq for clean output, but error will still show if they occur
    apt-get update -y -qq > /dev/null
    apt-get install -y -qq python3 python3-venv python3-pip curl git &> /dev/null
    
    log success "Core environment (Python, Venv, Git) installed."
}

# ? [Sets up Python virtual environment and installs dependencies]
setup_python_orchestrator() {
    log info "Setting up Python virtual environment..."
    
    if [ ! -d "$VENV_PATH" ]; then
        python3 -m venv "$VENV_PATH"
        log success "Virtual environment created."
    fi

    log info "Upgrading pip and installing requirements..."
    "$VENV_PATH/bin/pip" install -q --upgrade pip
    
    # Creating a placeholder requirements.txt if not exists
    if [ ! -f "requirements.txt" ]; then
        log warn "requirements.txt not found. Creating default..."
        echo -e "rich==13.7.0\nPyYAML==6.0.1" > requirements.txt
    fi

    "$VENV_PATH/bin/pip" install -q -r requirements.txt
    log success "Python environment is ready."
}

# ? [Executes the main Python automation entry point]
run_python_main() {
    if [ -f "core/main.py" ]; then
        log info "Handing over to Python Orchestrator...\n"
        "$VENV_PATH/bin/python" core/main.py
    else
        log error "Entry point 'core/main.py' not found!"
        exit 1
    fi
}

# ===== Main Execution =====
main() {
    clear
    print_banner

    check_root_access
    setup_sudo
    configure_user_permissions
    configure_repositories

    # Next steps
    check_network
    bootstrap_environment
    setup_python_orchestrator
    run_python_main
}

main "$@"