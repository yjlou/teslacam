#!/usr/bin/env bash
#
# A daemon to monitor the button press.
#
set -e
cd "$(dirname "$0")"
. common.sh
. mass_storage.sh

PRESSED=0  # 0: not pressed.
FAKE_BUTTON="FAKE_BUTTON"  # filename of the fake button (possible values: "0" or "1").
BUTTON_PIN=4
BOUNCE=0.01

button_init() {
  true
  echo "$BUTTON_PIN" > /sys/class/gpio/unexport  || true
  echo "$BUTTON_PIN" > /sys/class/gpio/export
  echo "1" > "/sys/class/gpio/gpio${BUTTON_PIN}/active_low"
  echo "in" > "/sys/class/gpio/gpio${BUTTON_PIN}/direction"
}

# Return the raw GPIO value (fake-able).
#
# Returns:
#   0:  true
#   1:  false
#
button_is_pressed_raw() {
  local value="$(cat $FAKE_BUTTON 2> /dev/null || true)"

  if [ -z "$value" ]; then
    value="$(< /sys/class/gpio/gpio${BUTTON_PIN}/value)"
  fi

  if [ "$value" = "1" ]; then
    return 0  # true
  else
    return 1  # false
  fi
}

# Call back the function when pressed or released (debounced).
#
button_callback() {
  local pressed=$1
  local released=$2

  if [ $PRESSED -eq 0 ]; then
    if button_is_pressed_raw; then
      sleep $BOUNCE
      if button_is_pressed_raw; then
        $pressed
        PRESSED=1
      fi
    fi
  elif [ $PRESSED -eq 1 ]; then
    if ! button_is_pressed_raw; then
      sleep $BOUNCE
      if ! button_is_pressed_raw; then
        $released
        PRESSED=0  # true
      fi
    fi
  fi
}

cb_pressed() {
  local min0=$(date --date="0 minutes ago" +"%Y-%m-%d_%H-%M-*.mp4")
  local min1=$(date --date="1 minutes ago" +"%Y-%m-%d_%H-%M-*.mp4")
  local min2=$(date --date="2 minutes ago" +"%Y-%m-%d_%H-%M-*.mp4")

  msg_debug "[BTN PRESSED]"
  mkdir -p "${MARKED_CLIPS}"
  (sleep $((2 * 60)); cp $RECENT_CLIPS/$min0 $RECENT_CLIPS/$min1 $RECENT_CLIPS/$min2 $MARKED_CLIPS/ || true) &
}

cb_released() {
  msg_debug "[BTN RELEASED]"
  sleep 5  # depress for a while to avoid flooding.
}

button_main() {
  FLAGS_HELP="USAGE: $0 [flags]"
  parse_args "$@"
  eval set -- "${FLAGS_ARGV}"

  echo "GPIO daemon on GPIO$BUTTO_PIN."
  button_init
  while true; do
    button_callback cb_pressed cb_released
    sleep $BOUNCE
  done
}

button_main "$@"
