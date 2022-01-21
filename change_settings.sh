#!/usr/bin/env bash
#
# This file contains the user's settings. Modified by user_settings.sh.
#
set -e
cd "$(dirname "$0")"
. common.sh

SETTINGS_TEMPLATE='conf/settings.sh.template'
SETTINGS_TEMPORARY='conf/settings.sh.temporary'
SETTINGS_SH='conf/settings.sh'

ask_and_replace() {
  local question="$1"
  local variable="$2"
  local default="$3"
  local answer=""

  read -r -p "$question" answer
  [ -z "$answer" ] && answer="$default"
  sed -i "s~^$variable=.*$~$variable='$answer'~g" "$SETTINGS_TEMPORARY"
}


change_settigs_main() {
  FLAGS_HELP="USAGE: $0 [flags]"
  parse_args "$@"
  eval set -- "${FLAGS_ARGV}"

  # Copy the template to the output file.
  cp -f "$SETTINGS_TEMPLATE" "$SETTINGS_TEMPORARY"

  # Guess the USB drive from the dmesg. Then ask how large the USB drive want to be.
  local device="/dev/$(dmesg | grep "Attached SCSI removable disk" | tail -n 1 | grep -oP 'sd[a-z]')"
  local disk_size=$(lsblk "$device" --output SIZE --nodeps | tail -n 1)
  if [ -z "$disk_size" ]; then
    echo "- I cannot figure out your USB drive."
  else
    echo "- Looks like your USB drive $device has $disk_size."
  fi
  ask_and_replace "How many space do you want to create for the camera to use (in GB)? " "USB_DRIVE_SIZE_GB"

  # WLAN
  echo "- WLAN"
  ask_and_replace "What's the WLAN SSID                              ? " "WLAN0_SSID"
  ask_and_replace "What's the WLAN password  (empty for open network)? " "WLAN0_PASSWORD"
  ask_and_replace "What's the WLAN IP address/mask   (empty for DHCP)? " "WLAN0_IPV4_ADDR"
  ask_and_replace "What's the WLAN IP gateway        (empty for DHCP)? " "WLAN0_IPV4_GW"

  # Ethernet
  echo "- Ethernet"
  ask_and_replace "What's the Ethernet IP address/mask  (empty for DHCP)? " "ETH0_IPV4_ADDR"
  ask_and_replace "What's the Ethernet IP gateway       (empty for DHCP)? " "ETH0_IPV4_GW"

  # Timezone
  echo "- Timezone"
  local def_tz="$(timedatectl |grep "Time zone" | awk '{ print $3}')"
  ask_and_replace "What's the timezone? Hints: 'timedatectl list-timezones' (empty to use local) " "TIMEZONE" "$def_tz"

  # SCP server
  echo "- SCP server"
  local scp_server_example="teslacam@your_server:/path/to/root/"
  ask_and_replace "What's the root path of the SCP server? (e.g. $scp_server_example)  " "SCP_ROOT" "$scp_server_example"
  ask_and_replace "What's the ID used to store video on the SCP server? (empty: '$USER') " "SCP_ID" "$USER"

  echo '------------------------------------------------'
  mv -f "$SETTINGS_TEMPORARY" "$SETTINGS_SH"
  msg_pass "Saved in '$SETTINGS_SH'."
  echo '------------------------------------------------'
  cat "$SETTINGS_SH"
}

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || change_settigs_main "$@"
