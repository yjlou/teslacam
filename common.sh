#!/usr/bin/env bash

set -e

. shflags

CONF_ID_RSA="conf/id_rsa"

COLOR_RED="\e[41;30m"
COLOR_GREEN="\e[42;30m"
COLOR_BLUE="\e[44;30m"
COLOR_YELLOW="\e[43;30m"
COLOR_WHITE="\e[0;37m"
COLOR_NO="\e[0m"

msg_debug() {
  local msg="$1"
  printf "${COLOR_NO}[ ${COLOR_BLUE}DEBUG${COLOR_NO} ]${COLOR_WHITE} $msg\n${COLOR_NO}"
}

msg_pass() {
  local msg="$1"
  printf "${COLOR_NO}[ ${COLOR_GREEN}PASS${COLOR_NO} ]${COLOR_WHITE} $msg\n${COLOR_NO}"
}

msg_warn() {
  local msg="$1"
  printf "${COLOR_NO}[ ${COLOR_YELLOW}WARN${COLOR_NO} ]${COLOR_WHITE} $msg\n${COLOR_NO}"
}

msg_fail() {
  local msg="$1"
  printf "${COLOR_NO}[ ${COLOR_RED}FAIL${COLOR_NO} ]${COLOR_WHITE} $msg\n${COLOR_NO}"
}

prepare_packages() {
  local test_cmd="$1"
  local packages="$2"

  if $test_cmd &> /dev/null; then
    return 0
  else
    msg_warn "The packages [$packages] is/are not installed. Installing ..."
    if sudo apt install -y $packages; then
      msg_pass "Installed: $packages"
    else
      msg_warn "Cannot install. Trying apt update and upgrade ..."
      if (sudo apt update -y && sudo apt upgrade -y && sudo apt install -y $packages); then
        msg_pass "Installed: $packages"
      else
        msg_fail "Failed to install: $packages"
        return 1
      fi
    fi
  fi

  if $test_cmd &> /dev/null; then
    return 0
  else
    msg_fail "After install, still failed to test: [$test_cmd]"
    return 1
  fi
}

# Used to parse the script arguments. Please pass in the arguments.
#
#   parse_args "$@"
#
parse_args() {
  # Common arguments. This will be applied to all scripts. Add wisely.
  #
  DEFINE_boolean 'do_nothing' false "Parse syntax only. Do nothing." 'n'
  DEFINE_boolean 'force' false "Force to run program anyway." 'f'

  # parse the command-line
  FLAGS "$@" || exit $?
  eval set -- "${FLAGS_ARGV}"

  if [ ${FLAGS_help} -eq ${FLAGS_TRUE} ]; then
    flags_help
    exit 1
  fi

  if [ ${FLAGS_do_nothing} -eq ${FLAGS_TRUE} ]; then
    msg_pass ""
    msg_pass "Done."
    msg_pass ""
    exit
  fi
}

is_running_on_arm() {
  if uname --machine | grep arm > /dev/null; then
    return true
  else
    return false
  fi
}

exit_if_running_on_rpi() {
  if is_running_on_arm; then
    echo "- Running on Raspberry Pi [$(uname -a)]."
    exit 56
  fi
}

exit_if_not_running_on_rpi() {
  if is_running_on_arm; then
    msg_pass "- Running on Raspberry Pi [$(uname -a)]."
  else
    msg_warn "- NOT running on Raspberry Pi. Instead, [$(uname -a)]."
    if [ ${FLAGS_force} -eq ${FLAGS_TRUE} ]; then
      msg_pass "  However, you are using -f to force continue."
      echo
    else
      msg_fail "  Stopped. Or you can use --force if you know what you are doing."
      exit 56
    fi
  fi
}

# Only append $lines when the $pattern is not found in the $file.
#
# Example:
#   append_if_not_existing /tmp/haha HAHA "$(printf '\n# HAHA\nB\nC')"
#
append_if_not_existing() {
  local filename="$1"
  local pattern="$2"
  local lines="$3"

  if ! grep -q "$pattern" "$filename"; then
    echo "$lines" >> "$filename"
  fi
}
