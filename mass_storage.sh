#!/usr/bin/env bash
#
# The library for g_mass_storage.
#
# Note that the USB drive image file is created at the first boot (by setup_system.sh). Thus, it
# could be absent.
#
set -e

USB_DRIVE_IMG=/root/usb_drive.img
USB_DRIVE_FOLDER=/media/
TESLA_CAM_FOLDER="${USB_DRIVE_FOLDER}/TeslaCam/"
RECENT_CLIPS="${TESLA_CAM_FOLDER}/RecentClips/"
SAVED_CLIPS="${TESLA_CAM_FOLDER}/SavedClips/"
MARKED_CLIPS="/root/MarkedClips/"

mount_ro_media() {
  # mount USB image onto system.
  if true; then
    mount -o ro "$USB_DRIVE_IMG" "${USB_DRIVE_FOLDER}"  || true
  else
    LOOP_DEV=$(losetup --show -Pf "${USB_DRIVE_IMG}")  || true
    mount -o loop,ro "${LOOP_DEV}"p1 "${USB_DRIVE_FOLDER}"  || true
  fi
}

mount_rw_media() {
  mount -o rw "$USB_DRIVE_IMG" "${USB_DRIVE_FOLDER}"  || true
}

umount_media() {
  umount -f "${USB_DRIVE_FOLDER}"
}

mass_storage_start() {
  # Load modules
  modprobe dwc2  || true
  modprobe g_mass_storage file="${USB_DRIVE_IMG}" stall=1 removable=1  || true
}

mass_storage_stop() {
  rmmod g_mass_storage
}
