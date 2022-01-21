#!/usr/bin/env bash
#
# Move the files on the server to local disk.
#
#
set -e
cd "$(dirname "$0")"
. common.sh
. conf/settings.sh

[ -z "$SCP_ROOT" ] && (msg_fail "Danger. SCP_ROOT is not defined" ; exit 1 )

DIR=/xpc/disk2/good_to_have_data/teslacam/

while true; do  \
  echo ""
  echo "Removing old directories ..."
  echo ""
  find "${DIR}" -maxdepth 2 -mtime +180 -type d -exec rm -rf '{}' \;

  echo ""
  echo "Rsyncing ..."
  echo ""
  time rsync --archive --remove-source-files -v -e "ssh -i ${CONF_ID_RSA}"  \
    "$SCP_ROOT"  \
    "${DIR}"  || true
  echo ""
  date
  echo "Sleep 12 hours ..."
  sleep $((12 * 3600))
  echo ""
  echo "-------------------"
  date
  echo ""
done

