#!/system/bin/sh
# FAF package.sh - Deteksi & informasi package aplikasi

# Cek package terinstal? return 0 jika ada
faf_pkg_exists() {
  pm list packages 2>/dev/null | grep -q "^package:${1}$"
}

# enabled / disabled / suspended / unknown
faf_pkg_state() {
  _pkg="$1"
  _dump="$(pm dump "$_pkg" 2>/dev/null)"
  [ -z "$_dump" ] && { echo "unknown"; return 1; }
  # Android menandai disabled via "disabled", "DISABLED", "suspended=true"
  if echo "$_dump" | grep -qi "suspended=true"; then echo "suspended"; return 0; fi
  # cek per-user state
  if pm list packages -d 2>/dev/null | grep -q "^package:${_pkg}$"; then
    echo "frozen"; return 0
  fi
  echo "active"; return 0
}

faf_is_frozen() { [ "$(faf_pkg_state "$1")" = "frozen" ] || [ "$(faf_pkg_state "$1")" = "suspended" ]; }

# Info singkat: "label|version|system|state"
faf_pkg_info() {
  _pkg="$1"
  faf_pkg_exists "$_pkg" || { echo "package tidak ditemukan: $_pkg" >&2; return 1; }
  _ver="$(dumpsys package "$_pkg" 2>/dev/null | grep -m1 "versionName=" | cut -d= -f2 | tr -d ' ')"
  [ -z "$_ver" ] && _ver="-"
  _sys="user"
  dumpsys package "$_pkg" 2>/dev/null | grep -qm1 "flags=.*SYSTEM" && _sys="system"
  _state="$(faf_pkg_state "$_pkg")"
  echo "${_pkg}|${_ver}|${_sys}|${_state}"
}

# Daftar semua package, satu per baris
faf_pkg_list_all()    { pm list packages 2>/dev/null | sed 's/^package://'; }
faf_pkg_list_user()   { pm list packages --user "${ANDROID_USER:-0}" 2>/dev/null | sed 's/^package://'; }
faf_pkg_list_frozen() { pm list packages -d 2>/dev/null | sed 's/^package://'; }

faf_require_pkg() {
  [ -n "$1" ] || { echo "package kosong" >&2; return 1; }
  faf_pkg_exists "$1" || { echo "package tidak ditemukan: $1" >&2; log_error "package tidak ditemukan: $1"; return 1; }
}
