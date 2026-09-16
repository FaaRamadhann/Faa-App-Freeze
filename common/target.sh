#!/system/bin/sh
# FAF target.sh - Management target.list
# Format: package:action  (action=freeze)

faf_target_list() {
  [ -f "$FAF_TARGET_FILE" ] || { echo "(target.list kosong)"; return 0; }
  grep -vE '^[[:space:]]*#' "$FAF_TARGET_FILE" | grep -vE '^[[:space:]]*$'
}

faf_target_add() {
  _pkg="$1"; _act="${2:-freeze}"
  [ -n "$_pkg" ] || { echo "usage: faf target add <package> [freeze]" >&2; return 1; }
  faf_require_pkg "$_pkg" || return 1
  mkdir -p "$(dirname "$FAF_TARGET_FILE")" 2>/dev/null
  [ -f "$FAF_TARGET_FILE" ] || echo "# Faa App Freezer targets" > "$FAF_TARGET_FILE"
  if grep -qE "^${_pkg}:" "$FAF_TARGET_FILE" 2>/dev/null; then
    _tmp="${FAF_TARGET_FILE}.tmp"
    sed "s|^${_pkg}:.*|${_pkg}:${_act}|" "$FAF_TARGET_FILE" > "$_tmp" && cat "$_tmp" > "$FAF_TARGET_FILE" && rm -f "$_tmp"
    echo "target updated: ${_pkg}:${_act}"
  else
    echo "${_pkg}:${_act}" >> "$FAF_TARGET_FILE"
    echo "target added: ${_pkg}:${_act}"
  fi
  log_info "target add ${_pkg}:${_act}"
}

faf_target_rm() {
  _pkg="$1"
  [ -n "$_pkg" ] || { echo "usage: faf target rm <package>" >&2; return 1; }
  [ -f "$FAF_TARGET_FILE" ] || { echo "target.list tidak ada" >&2; return 1; }
  if grep -qE "^${_pkg}:" "$FAF_TARGET_FILE" 2>/dev/null; then
    _tmp="${FAF_TARGET_FILE}.tmp"
    grep -vE "^${_pkg}:" "$FAF_TARGET_FILE" > "$_tmp" && cat "$_tmp" > "$FAF_TARGET_FILE" && rm -f "$_tmp"
    log_info "target remove $_pkg"
    echo "target removed: $_pkg"
  else
    echo "tidak ada di target: $_pkg" >&2; return 1
  fi
}

faf_target_clear() {
  grep -E '^[[:space:]]*#' "$FAF_TARGET_FILE" 2>/dev/null > "${FAF_TARGET_FILE}.tmp" || echo "# Faa App Freezer targets" > "${FAF_TARGET_FILE}.tmp"
  cat "${FAF_TARGET_FILE}.tmp" > "$FAF_TARGET_FILE"; rm -f "${FAF_TARGET_FILE}.tmp"
  log_info "target cleared"
  echo "targets cleared"
}

faf_target_check() {
  _pkg="$1"
  grep -qE "^${_pkg}:" "$FAF_TARGET_FILE" 2>/dev/null
}
