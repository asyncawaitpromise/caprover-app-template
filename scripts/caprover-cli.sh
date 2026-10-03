#!/usr/bin/env bash
# Sourced by the scripts that call the caprover CLI.
#
# An expired CLI session makes the caprover CLI fall back to an interactive
# password prompt instead of failing, which hangs forever without a TTY.
# These wrappers close stdin and enforce a timeout so that case fails fast.

CAPROVER_LIST_TIMEOUT_SECONDS=15
CAPROVER_API_TIMEOUT_SECONDS=30

print_session_expired_hint() {
  echo "Error: caprover CLI call failed — your CapRover CLI session may have expired." >&2
  echo "       Try: caprover login" >&2
}

run_caprover_with_timeout() {
  local timeout_seconds="$1"
  shift

  local exit_code=0
  timeout "$timeout_seconds" caprover "$@" < /dev/null || exit_code=$?

  if [[ "$exit_code" -ne 0 ]]; then
    print_session_expired_hint
  fi
  return "$exit_code"
}

caprover_list() {
  run_caprover_with_timeout "$CAPROVER_LIST_TIMEOUT_SECONDS" ls
}

caprover_api() {
  run_caprover_with_timeout "$CAPROVER_API_TIMEOUT_SECONDS" api "$@"
}
