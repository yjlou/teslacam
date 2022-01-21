#!/usr/bin/env bash
#
# This script provides the library to backup video.
#
#
set -e
cd "$(dirname "$0")"
. common.sh
. mass_storage.sh
. upload.sh

RSYNC='rsync -av --remove-source-files'
RSYNC_TEMP='/tmp/teslacam'

backup_start() {
  # copy to local first.
  mkdir -p "${RSYNC_TEMP}"
  mv -f "${MARKED_CLIPS}/"* "${RSYNC_TEMP}/"  || true

  $RSYNC "${SAVED_CLIPS}/" "${RSYNC_TEMP}/"  || true
  find "${SAVED_CLIPS}" -depth -type d -empty -exec rmdir "{}" \;
  mkdir -p "${SAVED_CLIPS}"  # the previous 'find' can remove the directory.

  # upload files.
  export -f upload_file_scp
  find "${RSYNC_TEMP}" -type f -exec bash -c 'upload_file_scp "$0" "$1" "$2"' {} "$SCP_ROOT/" "$SCP_ID" \;

  msg_pass "Backup Done."
}
