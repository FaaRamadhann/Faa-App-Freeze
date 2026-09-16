#!/system/bin/sh
# FAF freeze.sh - Logic freeze / unfreeze aplikasi
# Satu-satunya backend freeze. Manager APK & CLI sama-sama lewat sini.
# Metode: disable (pm disable-user) default | suspend (pm suspend API29+)

faf_freeze() {
  _pkg="$1"
  faf_require_pkg "$_pkg" || return 1
  _method="$(faf_config_get FREEZE_METHOD disable)"
  _user="${ANDROID_USER:-0}"
  if faf_is_frozen "$_pkg"; then echo "$_pkg already frozen"; return 0; fi
  if [ "$_method" = "suspend" ]; then
    if pm suspend --user "$_user" "$_pkg" 2>/dev/null; then
      log_info "$_pkg frozen (suspend)"
      echo "$_pkg frozen"
      return 0
    else
      log_warn "suspend gagal untuk $_pkg, fallback ke disable"
    fi
  fi
  # default: disable-user (mirip Hail)
  if pm disable-user --user "$_user" "$_pkg" >/dev/null 2>&1; then
    log_info "$_pkg frozen (disable-user)"
    [ "$(faf_config_get RESTART_PROTECTION true)" = "true" ] && am force-stop "$_pkg" >/dev/null 2>&1
    echo "$_pkg frozen"
    return 0
  else
    log_error "gagal freeze $_pkg"
    echo "gagal freeze $_pkg" >&2; return 1
  fi
}

faf_unfreeze() {
  _pkg="$1"
  faf_require_pkg "$_pkg" || return 1
  _user="${ANDROID_USER:-0}"
  # coba kedua metode enable agar bersih dari suspend maupun disable
  pm unsuspend --user "$_user" "$_pkg" >/dev/null 2>&1
  if pm enable "$_pkg" >/dev/null 2>&1; then
    log_info "$_pkg unfrozen"
    echo "$_pkg unfrozen"
    return 0
  else
    # fallback: enable per-user
    if pm enable --user "$_user" "$_pkg" >/dev/null 2>&1; then
      log_info "$_pkg unfrozen"
      echo "$_pkg unfrozen"; return 0
    fi
    log_error "gagal unfreeze $_pkg"
    echo "gagal unfreeze $_pkg" >&2; return 1
  fi
}

faf_toggle() {
  _pkg="$1"
  faf_require_pkg "$_pkg" || return 1
  if faf_is_frozen "$_pkg"; then faf_unfreeze "$_pkg"; else faf_freeze "$_pkg"; fi
}

# Freeze semua package di target.list yang action=freeze
faf_apply_targets() {
  _ok=0; _fail=0
  while IFS= read -r _line || [ -n "$_line" ]; do
    case "$_line" in ''|\#*) continue ;; esac
    _pkg="$(echo "$_line" | cut -d: -f1 | tr -d ' ')"
    _act="$(echo "$_line" | cut -d: -f2 | tr -d ' ')"
    [ -z "$_pkg" ] && continue
    [ -z "$_act" ] && _act="freeze"
    if [ "$_act" = "freeze" ]; then
      if faf_freeze "$_pkg" >/dev/null 2>&1; then _ok=$((_ok+1)); else _fail=$((_fail+1)); fi
    fi
  done < "$FAF_TARGET_FILE"
  log_info "target applied: ok=$_ok fail=$_fail"
  echo "applied: ok=$_ok fail=$_fail"
}

# Unfreeze semua yang pernah dibekukan FAF (berdasar target.list + state disabled)
faf_unfreeze_all_managed() {
  _n=0
  for _p in $(pm list packages -d 2>/dev/null | sed 's/^package://'); do
    # hanya yang ada di target.list agar tidak menyentuh disabled sistem lain
    if grep -qE "^${_p}:" "$FAF_TARGET_FILE" 2>/dev/null; then
      faf_unfreeze "$_p" >/dev/null 2>&1 && _n=$((_n+1))
    fi
  done
  log_info "unfreeze all managed: $_n"
  echo "unfrozen: $_n"
}
