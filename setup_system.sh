#!/usr/bin/env bash
#
# This script assumes only running once.
#
set -e
cd "$(dirname "$0")"
. common.sh
. nmcli.sh
. mass_storage.sh
. conf/settings.sh

echo "- Setting up the locale and keyboard ..."
wget -O - https://gist.githubusercontent.com/adoyle/71803222aff301da9662/raw/e40f2a447e0ae333801e6fddf5e6bdb7430c289d/raspi-init.sh | bash
timedatectl set-timezone "$TIMEZONE"

# Install necessary packges
prepare_packages "xxd -v" "xxd"
prepare_packages "curl -V" "curl"
prepare_packages "tmux -V" "tmux"

# Configure the network interfaces (this must be the last one since nmcli can change the network
# settings and fail to connect network again.
nmcli_setup
nmcli_ethernet_static eth0 "$ETH0_IPV4_ADDR" "$ETH0_IPV4_GW"
nmcli_wifi_static wlan0 "$WLAN0_IPV4_ADDR" "$WLAN0_IPV4_GW" "$WLAN0_SSID" "$WLAN0_PASSWORD"

# Enable ssh
sudo systemctl enable ssh
sudo systemctl start ssh

# Create the USB drive image file.
#
# We havbe to create the file here (after the partition is expanded).
#
echo "Creating the USB drive image."
sudo nice -n +19 dd status=progress if=/dev/zero of="${USB_DRIVE_IMG}" bs=1M count="$USB_DRIVE_SIZE_MB"
sudo mkdosfs -F 32 -I "${USB_DRIVE_IMG}"
mount_rw_media
# Create directories for Tesla Camera
sudo mkdir -p "${RECENT_CLIPS}"
sudo mkdir -p "${SAVED_CLIPS}"
sudo mkdir -p "${MARKED_CLIPS}"
umount_media

# Schedule a shutdown to inform the user everything is done.
(sleep 10; shutdown -h now) &
