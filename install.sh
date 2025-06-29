#!/bin/bash

set -e

THEME_NAME="tuxsona"
THEME_DIR="/usr/share/plymouth/themes/$THEME_NAME"
PLYMOUTH_CONF="/usr/share/plymouth/plymouthd.defaults"
GRUB_FILE="/etc/default/grub"
MKINITCPIO_FILE="/etc/mkinitcpio.conf"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function confirm_action() {
    local action="$1"
    read -p "⚠️ Are you sure you want to ${action}? (y/n) " answer
    [[ "$answer" =~ ^[Yy]$ ]] || exit 0
}

function check_theme_exists() {
    [ -d "$THEME_DIR" ]
}

function install_theme() {
    echo -e "${GREEN}📦 Installing Plymouth theme '$THEME_NAME'...${NC}"

    if check_theme_exists; then
        read -p "⚠️ Theme already exists at $THEME_DIR. Replace it? (y/n) " answer
        [[ "$answer" =~ ^[Yy]$ ]] || { echo -e "${YELLOW}❌ Installation aborted.${NC}"; exit 1; }
        sudo rm -rf "$THEME_DIR"
    fi

    if [ ! -d "$(pwd)/$THEME_NAME" ]; then
        echo -e "${RED}❌ Theme folder '$THEME_NAME' not found in current directory.${NC}"
        exit 1
    fi

    sudo cp -r "$(pwd)/$THEME_NAME" "$THEME_DIR"
    
    # Ensure .plymouth file exists
    if [ ! -f "$THEME_DIR/$THEME_NAME.plymouth" ]; then
        found_file=$(find "$THEME_DIR" -name "*.plymouth" | head -n 1)
        [ -n "$found_file" ] && sudo mv "$found_file" "$THEME_DIR/$THEME_NAME.plymouth"
    fi

    sudo plymouth-set-default-theme -R "$THEME_NAME"
    echo -e "${GREEN}✅ Theme installed and configured. Current theme: $(plymouth-set-default-theme)${NC}"
}

function uninstall_theme() {
    echo -e "${YELLOW}🗑️ Uninstalling Plymouth theme '$THEME_NAME'...${NC}"
    
    if ! check_theme_exists; then
        echo -e "${YELLOW}⚠️ Theme not found at $THEME_DIR${NC}"
        exit 0
    fi

    confirm_action "uninstall this theme"
    
    sudo rm -rf "$THEME_DIR"
    echo -e "${GREEN}✅ Theme removed.${NC}"

    # Reset to default theme if uninstalled theme was active
    if [ "$(plymouth-set-default-theme)" == "$THEME_NAME" ]; then
        sudo plymouth-set-default-theme -R "details"
        echo -e "${GREEN}✅ Reset to default Plymouth theme.${NC}"
    fi

    update_initramfs
}

function configure_plymouth() {
    echo -e "${GREEN}🔧 Configuring Plymouth system settings...${NC}"
    confirm_action "configure Plymouth system settings"
    
    # Configure GRUB
    echo -e "${YELLOW}⚙️ Updating GRUB configuration...${NC}"
    sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/&quiet splash vt.global_cursor_default=0 /' "$GRUB_FILE"
    sudo update-grub

    # Configure mkinitcpio (for Arch-based systems)
    if [ -f "$MKINITCPIO_FILE" ] && ! grep -q "plymouth" "$MKINITCPIO_FILE"; then
        echo -e "${YELLOW}⚙️ Adding Plymouth hook to mkinitcpio...${NC}"
        sudo sed -i 's/^HOOKS=(/&plymouth /' "$MKINITCPIO_FILE"
    fi

    # Update initramfs
    update_initramfs
    
    echo -e "${GREEN}✅ Plymouth configuration complete. Reboot to see changes.${NC}"
}

function update_initramfs() {
    echo -e "${YELLOW}🔄 Updating initramfs...${NC}"
    if command -v update-initramfs &>/dev/null; then
        sudo update-initramfs -u
    elif command -v dracut &>/dev/null; then
        sudo dracut -f
    else
        echo -e "${RED}❌ No initramfs update tool found!${NC}"
        exit 1
    fi
}

case "$1" in
    --install)
        install_theme
        ;;
    --uninstall)
        uninstall_theme
        ;;
    --configure)
        configure_plymouth
        ;;
    *)
        echo "Usage: $0 --install | --uninstall | --configure"
        exit 1
        ;;
esac
