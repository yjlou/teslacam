#!/bin/bash
set -e

. common.sh
. conf/settings.sh

upload_file_scp() {
  local infile="$1"
  local scp_root="$2"
  local scp_id="$3"
  local filename="$(basename $infile)"
  echo "Uploading [${filename}] ..."

  if scp -o UpdateHostKeys=yes -o StrictHostKeyChecking=no "$infile" "$scp_root/$scp_id/"; then
    rm -f ${infile}
  else
    echo "Error uploading [${filename}] ..."
  fi
}

upload_main() {
  FLAGS_HELP="USAGE: $0 [flags]"
  parse_args "$@"
  eval set -- "${FLAGS_ARGV}"

  if [ "$#" -ne 1 ]; then
    flags_help
    exit 1
  fi

  local infile="$1"
  local scp_root="$2"
  local scp_id="$3"
  upload_file "${infile}" "${SCP_ROOT}" "${SCP_ID}"
}

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || upload_main "$@"
