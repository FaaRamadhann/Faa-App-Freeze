#!/system/bin/sh
# FAF logger.sh - Logging system FAF
# Log ke $FAF_LOG_FILE, format: "YYYY-MM-DD HH:MM:SS LEVEL message"

FAF_LOG_LEVEL_NUM() {
  case "$1" in
    DEBUG) echo 0 ;;
    INFO)  echo 1 ;;
    WARN)  echo 2 ;;
    ERROR) echo 3 ;;
    *)     echo 1 ;;
  esac
}

FAF_LOG_SHOULD_WRITE() {
  _cur="$(FAF_LOG_LEVEL_NUM "${LOG_LEVEL:-INFO}")"
  _msg="$(FAF_LOG_LEVEL_NUM "$1")"
  [ "$_msg" -ge "$_cur" ]
}

_faf_log_write() {
  _level="$1"; shift
  FAF_LOG_SHOULD_WRITE "$_level" || return 0
  _ts="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "---- -- --:--:--")"
  _line="$_ts  $_level  $*"
  # selalu ke stdout juga bila DEBUG atau dipanggil dari terminal
  if [ -n "${FAF_LOG_FILE:-}" ]; then
    mkdir -p "$(dirname "$FAF_LOG_FILE")" 2>/dev/null
    echo "$_line" >> "$FAF_LOG_FILE" 2>/dev/null
  fi
  # echo ke stderr hanya untuk WARN/ERROR supaya CLI tetap bersih
  case "$_level" in
    WARN|ERROR) echo "faf: $_level: $*" >&2 ;;
  esac
}

log_debug() { _faf_log_write DEBUG "$*"; }
log_info()  { _faf_log_write INFO  "$*"; }
log_warn()  { _faf_log_write WARN  "$*"; }
log_error() { _faf_log_write ERROR "$*"; }

# Dipakai daemon/manager untuk baca log dari CLI: faf logs
faf_logs_print() {
  if [ -f "$FAF_LOG_FILE" ]; then
    cat "$FAF_LOG_FILE"
  else
    echo "(log kosong: $FAF_LOG_FILE belum ada)"
  fi
}

faf_logs_clear() {
  : > "$FAF_LOG_FILE" 2>/dev/null
  log_info "logs cleared"
  echo "logs cleared: $FAF_LOG_FILE"
}
