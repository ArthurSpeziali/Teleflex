#!/usr/bin/env bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 TOKEN DOMAIN"
    exit 1
fi

TOKEN="$1"
DOMAIN="$2"
INSTALL_DIR="$HOME/.duckdns"
SCRIPT_FILE="$INSTALL_DIR/duck.sh"
LOG_FILE="$INSTALL_DIR/duck.log"

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)

install_cron() {
    case "$DISTRO" in
        debian|ubuntu)
            if ! command -v cron >/dev/null 2>&1; then
                echo "Installing cron..."
                sudo apt update && sudo apt install -y cron
                sudo systemctl enable --now cron
            fi
            ;;
        fedora|rhel|centos)
            if ! command -v crond >/dev/null 2>&1; then
                echo "Installing cronie..."
                sudo dnf install -y cronie
                sudo systemctl enable --now crond
            fi
            ;;
        arch)
            if ! command -v cronie >/dev/null 2>&1; then
                echo "Installing cronie..."
                sudo pacman -S --noconfirm --needed cronie
                sudo systemctl enable --now cronie
            fi
            ;;
        macos)
            echo "macOS detected. Please install cron via brew or use launchd manually."
            ;;
        *)
            echo "Unknown distro: $DISTRO. Please install cron manually."
            ;;
    esac
}


setup_duckdns_script() {
    mkdir -p "$INSTALL_DIR"
    cat > "$SCRIPT_FILE" <<EOF
#!/bin/bash
echo url="https://www.duckdns.org/update?domains=$DOMAIN&token=$TOKEN&ip=\$(curl -6 ifconfig.me)" \\
| curl -k -o "$LOG_FILE" -K -
EOF
    chmod +x "$SCRIPT_FILE"
    echo "Script created at: $SCRIPT_FILE"
}

add_crontab() {
    if ! crontab -l 2>/dev/null | grep -q "$SCRIPT_FILE"; then
        (crontab -l 2>/dev/null; echo "*/5 * * * * $SCRIPT_FILE >/dev/null 2>&1") | crontab -
        echo "Cron job set to run every 5 minutes"
    else
        echo "Cron job already set"
    fi
}

echo "Detected distro: $DISTRO"

install_cron
setup_duckdns_script

if [[ "$DISTRO" == "macos" ]]; then
    echo "Add cron job manually:"
    echo "crontab -e"
    echo "*/5 * * * * $SCRIPT_FILE >/dev/null 2>&1"
else
    add_crontab
fi

echo "Running initial update..."
bash "$SCRIPT_FILE"

echo "DuckDNS setup complete."
echo "Directory: $INSTALL_DIR"
