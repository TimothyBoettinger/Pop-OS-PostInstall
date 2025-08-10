#!/bin/bash
#
# Pop!_OS Setup Script for Gaming & C Development
#
# This script is designed to be run on a fresh Pop!_OS installation.
# It will update the system, install development tools, desktop apps,
# and handle custom installations like XDM.
#
# USAGE:
# 1. Save this script as `setup.sh`.
# 2. Make it executable: `chmod +x setup.sh`
# 3. Run it: `./setup.sh`
#
# I run NVIDIA Drivers so will need this command but feel free to remove
# sudo apt install system76-driver-nvidia

# --- Script Configuration ---
# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# The return value of a pipeline is the status of the last command to exit with a non-zero status.
set -o pipefail

# --- Package Lists ---

# APT packages are best for core utilities, CLI tools, and development libraries.
apt_packages=(
    # C Development Environment
    build-essential
    clang
    gdb
    valgrind
    cmake
    manpages-dev
    neovim

    # System & Utilities
    system76-driver-nvidia
    gnome-tweaks
    ubuntu-restricted-extras
    neofetch
    cmatrix
    rustup

    # Gaming & Emulation Support
    steam-installer
    lutris
    wine
    
    # Required for XDM
    openjdk-17-jre
)

# Flatpak is best for desktop applications to get the latest versions.
flatpak_packages=(
    # Media & Gaming
    com.obsproject.Studio           # OBS Studio
    org.videolan.VLC                # VLC
    io.github.librewolf-community   # LibreWolf
    org.mixxx.Mixxx                 # Mixxx
    org.qbittorrent.qBittorrent     # qBittorrent

    # Other Apps
    com.pokemmo.PokeMMO
    net.davidotek.pupgui2
)


# --- Functions ---

add_nicotine_ppa() {
    echo "--- Adding Nicotine+ PPA ---"
    # Nicotine+ is best installed from its PPA for the latest version.
    sudo add-apt-repository -y ppa:nicotine-team/stable
    # Add the package to our main APT list
    apt_packages+=(nicotine+)
}

install_xdm() {
    echo "--- Installing Xtreme Download Manager (XDM) ---"
    local xdm_url="https://github.com/subhra74/xdm/releases/download/8.0.29/xdm-setup-8.0.29.tar.xz"
    local temp_dir
    temp_dir=$(mktemp -d) # Create a temporary directory securely

    echo "Downloading XDM..."
    wget -O "$temp_dir/xdm.tar.xz" "$xdm_url"

    echo "Extracting and installing XDM..."
    tar -xvf "$temp_dir/xdm.tar.xz" -C "$temp_dir"
    
    # Make the installer executable and run it with sudo
    chmod +x "$temp_dir/install.sh"
    sudo "$temp_dir/install.sh"

    echo "Cleaning up XDM temporary files..."
    rm -rf "$temp_dir"
}


# --- Main Execution ---

# Ensure script is not run as root, but can use sudo.
if [ "$(id -u)" -eq 0 ]; then
  echo "This script should not be run as root. Please run as a user with sudo privileges." >&2
  exit 1
fi

echo "--- STARTING SYSTEM SETUP & REINSTALL SCRIPT ---"

# 1. Add External Repositories
add_nicotine_ppa

# 2. Update and Upgrade the Base System
echo "--- Updating package lists and upgrading the core system ---"
sudo apt update
sudo apt full-upgrade -y
sudo apt autoremove --purge -y

# 3. Install APT Packages
echo "--- Installing APT packages ---"
sudo apt install -y "${apt_packages[@]}"

# 4. Install Xtreme Download Manager
install_xdm

# 5. Install Rust Toolchain (as the current user, not root)
echo "--- Installing Rust toolchain ---"
rustup-init -y --no-modify-path

# 6. Set up Flatpak and Install Applications
echo "--- Setting up Flatpak and installing applications ---"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak update -y
flatpak install -y --noninteractive flathub "${flatpak_packages[@]}"

# 7. Final Cleanup
echo "--- Performing final cleanup ---"
sudo apt autoremove --purge -y

echo ""
echo " --- SCRIPT FINISHED ---"
echo "Please reboot your system for all changes to take effect."
