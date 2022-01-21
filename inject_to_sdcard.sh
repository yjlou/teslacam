#!/usr/bin/env bash
#
# This script will inject settings and files into the sdcard.
#
set -e
cd "$(dirname "$0")"
. common.sh
. mass_storage.sh
. change_settings.sh

MOUNT_ROOT="/media/$USER/"

umount_all() {
  echo "Umounting ..."
  sudo umount "${MOUNT_ROOT}/boot" "${MOUNT_ROOT}/rootfs" || true
  sudo rmdir "${MOUNT_ROOT}/boot" "${MOUNT_ROOT}/rootfs" || true
}

mount_all() {
  local device="$1"
  echo "Mounting $device ..."

  sudo mkdir -p "${MOUNT_ROOT}/boot" "${MOUNT_ROOT}/rootfs"
  sudo mount "${device}1" "${MOUNT_ROOT}/boot"
  sudo mount "${device}2" "${MOUNT_ROOT}/rootfs"
}

main() {
  local img_file="$1"
  local device="$2"

  # Prompt user if user config file is not generated yet.
  if [ ! -f "$SETTINGS_SH" ]; then
    msg_fail "'$SETTINGS_SH' is not found. Please run ./change_settings.sh to generate it."
    exit 2
  fi

  # Require the SD card device.
  if [ -z "$device" ]; then
    msg_fail "Please provide the device (ex /dev/sdz) of the SD card."
    echo
    flags_help
    exit 1
  fi

  # Warn the user.
  msg_warn "This will destroy the $device. Please confirm before we move on!"
  if [ ${FLAGS_force} -ne ${FLAGS_TRUE} ]; then
    read -r -p "Are you sure? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            exit 1
            ;;
    esac
  fi

  echo "- Unmounting existing partitions (if any) ..."
  umount_all

  # Overwrite the drive!
  echo "- Write the Raspberry Pi image into SD card [$device] ..."
  sudo dd if="$img_file" of="$device" bs=1M status=progress
  echo "- Re-detect the partition ..."
  sudo partprobe "$device"  # re-detect the partition table.
  sleep 3
  echo "- Mounting SD card ..."
  mount_all "$device"
  
  ###########################################################################
  #
  #  Let's do some real works now !!!!!
  #
  ###########################################################################

  local PROGRAM_DIR="${MOUNT_ROOT}/rootfs/root/teslacam"
  echo "- Copying all scripts into $PROGRAM_DIR ..."
  sudo mkdir -p "$PROGRAM_DIR"
  sudo cp -v -rf -L * "$PROGRAM_DIR"

  # Copy ssh credential for the host to login.
  #
  echo "- Copy ssh credential ..."
  local SSH_ROOT="${MOUNT_ROOT}/rootfs/root/.ssh/"
  sudo mkdir -p "$SSH_ROOT"
  # For user to login this device.
  #
  cat ~/.ssh/id_rsa.pub | sudo tee -a "$SSH_ROOT"/authorized_keys
  # For this device to upload.
  #
  local reminder=""
  if [ ! -f "${CONF_ID_RSA}" ]; then
    echo "- Generating [${CONF_ID_RSA}] ..."
    ssh-keygen -t rsa -C root@teslacam -N '' -f "${CONF_ID_RSA}"
    reminder="* Please manually copy ${CONF_ID_RSA}.pub file to your SCP server ($SCP_ROOT)."
  fi
  cat "${CONF_ID_RSA}" | sudo tee -a "$SSH_ROOT"/id_rsa > /dev/null
  sudo chmod 600 "$SSH_ROOT"/id_rsa
  cat "${CONF_ID_RSA}".pub | sudo tee -a "$SSH_ROOT"/id_rsa.pub

  # Copy .bashrc and .tmux files
  sudo cp conf/.bashrc conf/.tmux.conf "${MOUNT_ROOT}/rootfs/root/"

  # Configure gadget mass storage.
  local BOOT_CONFIG_FILE="${MOUNT_ROOT}/boot/config.txt"
  echo "- Configure '$BOOT_CONFIG_FILE' ..."
  echo "dtoverlay=dwc2" | sudo tee -a "$BOOT_CONFIG_FILE"
  echo "hdmi_force_hotplug=1" | sudo tee -a "$BOOT_CONFIG_FILE"

  # rc.local
  #
  local RC_LOCAL_FILE="${MOUNT_ROOT}/rootfs/etc/rc.local"
  echo "- Remove the last line of the '$RC_LOCAL_FILE' ..."
  sudo sed -i '$d' "$RC_LOCAL_FILE"  # "exit 0"

  echo "- Install run once program into '$RC_LOCAL_FILE' ..."
  echo "/root/teslacam/run_once.sh /root/teslacam/setup_system.sh >> /var/log/setup.log 2>&1" | sudo tee -a "$RC_LOCAL_FILE"

  echo "- Install programs into '$RC_LOCAL_FILE' ..."
  echo "tmux new-session -d -s teslacam -n context" | sudo tee -a "$RC_LOCAL_FILE"
  echo "tmux send-keys -t teslacam:context '/root/teslacam/context.sh' Enter" | sudo tee -a "$RC_LOCAL_FILE"
  echo "tmux new-window -t teslacam -n button" | sudo tee -a "$RC_LOCAL_FILE"
  echo "tmux send-keys -t teslacam:button '/root/teslacam/button.sh' Enter" | sudo tee -a "$RC_LOCAL_FILE"

  # Move back the "exit 0" line.
  echo "- Add back the last line into '$RC_LOCAL_FILE' ..."
  echo "exit 0" | sudo tee -a "$RC_LOCAL_FILE"

  # Tear down ...
  sync
  sleep 3  # Somehow we need this to avoid the device busy issue.
  umount_all
  sync
  sync
  # sudo udisksctl power-off -b "$device"

  msg_pass "Done"
  echo
  echo "$reminder"
}

FLAGS_HELP="USAGE: $0 [flags] image_file /dev/sdcard"
parse_args "$@"
eval set -- "${FLAGS_ARGV}"
main "$@"
