#!/system/bin/sh
# FAF config.sh - Management konfigurasi FAF
# Config runtime: $FAF_CONFIG_FILE (default /data/adb/faf/config.conf)

faf_config_get() {
  # usage: faf_config_get KEY [default]
  _key="$1"; _def="$2"
  _val=""
  if [ -f "$FAF_CONFIG_FILE" ]; then
    _val="$(grep -E "^[[:space:]]*${_key}[[:space:]]*=" "$FAF_CONFIG_FILE" 2>/dev/null | tail -n 1 | cut -d= -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  fi
  if [ -z "$_val" ]; then echo "$_def"; else echo "$_val"; fi
}

faf_config_set() {
  # usage: faf_config_set KEY VALUE
  _key="$1"; _val="$2"
  [ -z "$_key" ] && { echo "usage: faf config set <key> <value>" >&2; return 1; }
  mkdir -p "$(dirname "$FAF_CONFIG_FILE")" 2>/dev/null
  [ -f "$FAF_CONFIG_FILE" ] || touch "$FAF_CONFIG_FILE"
  if grep -qE "^[[:space:]]*${_key}[[:space:]]*=" "$FAF_CONFIG_FILE" 2>/dev/null; then
    _tmp="${FAF_CONFIG_FILE}.tmp"
    sed "s|^[[:space:]]*${_key}[[:space:]]*=.*|${_key}=${_val}|" "$FAF_CONFIG_FILE" > "$_tmp" 2>/dev/null \
      && cat "$_tmp" > "$FAF_CONFIG_FILE" && rm -f "$_tmp"
  else
    echo "${_key}=${_val}" >> "$FAF_CONFIG_FILE"
  fi
  log_info "config set ${_key}=${_val}"
  echo "${_key}=${_val}"
}

faf_config_show() {
  if [ -f "$FAF_CONFIG_FILE" ]; then
    grep -vE '^[[:space:]]*#' "$FAF_CONFIG_FILE" | grep -vE '^[[:space:]]*$'
  else
    echo "(config tidak ada: $FAF_CONFIG_FILE)" >&2; return 1
  fi
}

faf_config_reset() {
  _default_src="$MODPATH/config/config.conf"
  [ -f "$_default_src" ] || _default_src="$FAF_DIR_DEFAULT_CONFIG"
  if [ -f "$_default_src" ]; then
    cp -f "$_default_src" "$FAF_CONFIG_FILE"
    log_info "config reset to default"
    echo "config reset: $FAF_CONFIG_FILE"
  else
    echo "default config tidak ditemukan" >&2; return 1
  fi
}

# Muat config ke variabel shell (AUTO_FREEZE, FREEZE_DELAY, dst.)
faf_config_load() {
  AUTO_FREEZE="$(faf_config_get AUTO_FREEZE true)"
  FREEZE_DELAY="$(faf_config_get FREEZE_DELAY 60)"
  APPLY_ON_BOOT="$(faf_config_get APPLY_ON_BOOT true)"
  FREEZE_METHOD="$(faf_config_get FREEZE_METHOD disable)"
  RESTART_PROTECTION="$(faf_config_get RESTART_PROTECTION true)"
  TARGET_ONLY="$(faf_config_get TARGET_ONLY true)"
  ANDROID_USER="$(faf_config_get ANDROID_USER 0)"
  LOG_LEVEL="$(faf_config_get LOG_LEVEL INFO)"
  case "$FREEZE_DELAY" in ''|*[!0-9]*) FREEZE_DELAY=60 ;; esac
}
