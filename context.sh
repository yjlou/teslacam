#!/usr/bin/env bash
#
# This script will run as a daemon and keep probing whether the user comes home.
#
set -e
cd "$(dirname "$0")"
. common.sh
. mass_storage.sh
. backup.sh

NEW_STATE='NEW_STATE'

context_main() {
  FLAGS_HELP="USAGE: $0 [flags]"
  parse_args "$@"
  eval set -- "${FLAGS_ARGV}"

  local state="INIT"

  while true; do

    local gateway="$(nmcli con show "$WLAN0_SSID" 2> /dev/null | grep ipv4.gateway | awk '{print $2}')"
    [ -z "$gateway" ] && gateway="$WLAN0_IPV4_GW"
    if [ -z "$gateway" ]; then
      msg_warn "No gateway info. Don't know what to ping. Retry soon."
      sleep 5
      continue
    fi

    # If a local file is present, overwrite the new state string.
    # Otherwise, ping gateway to detect it.
    local new_state="$(cat $NEW_STATE 2> /dev/null || true)"
    if [ -z "$new_state" ]; then
      if ping -c 4 -W 1 "$gateway" &> /dev/null ; then
        new_state="HOME"
      else
        new_state="AWAY"
      fi
    fi

    if [ "$state" != "$new_state" ]; then
      echo "[ $state ] --> [ $new_state ]"
    fi

    # FIXME: set state in unknown for retry when failure.
    if [ "$state" != "HOME" -a "$new_state" = "HOME" ]; then
      # Just come home! Disable the USB drive.
      umount_media  || true
      mass_storage_stop  || true
      mount_rw_media  || true
      backup_start  || true

    elif [ "$state" != "AWAY" -a "$new_state" = "AWAY" ]; then
      # We are leaving. Enable the USB drive.
      umount_media  || true
      mass_storage_start  || true
      mount_ro_media  || true

    fi

    state="$new_state"

    sleep 63
  done
}


[[ "${BASH_SOURCE[0]}" != "${0}" ]] || context_main "$@"
