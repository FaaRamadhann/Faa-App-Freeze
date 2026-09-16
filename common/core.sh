#!/system/bin/sh
# FAF core.sh - Core logic: path runtime, init, loader backend
# Di-source oleh /system/bin/faf, service.sh, action.sh, uninstall.sh

# Lokasi runtime (persistent). Prioritas: /data/adb/faf, fallback modul.
if [ -d /data/adb/faf ]; then
  FAF_DATA=/data/adb/faf
else
  FAF_DATA=/data/adb/modules/faafreeze
fi
# MODPATH diisi Magisk saat service/customize; fallback tebak lokasi modul
if [ -z "${MODPATH:-}" ]; then
  for _c in /data/adb/modules/faafreeze /data/adb/modules_update/faafreeze; do
    [ -f "$_c/common/core.sh" ] && MODPATH="$_c" && break
  done
fi
[ -n "${MODPATH:-}" ] && [ -d "$MODPATH" ] || MODPATH="$(dirname "$(dirname "$0")")"

FAF_CONFIG_FILE="$FAF_DATA/config.conf"
FAF_TARGET_FILE="$FAF_DATA/target.list"
FAF_LOG_FILE="$FAF_DATA/logs/faf.log"
FAF_STATE_DIR="$FAF_DATA/state"
FAF_PROFILES_DIR="$FAF_DATA/profiles"
FAF_DIR_DEFAULT_CONFIG="$MODPATH/config/config.conf"
FAF_DIR_DEFAULT_TARGET="$MODPATH/config/target.list"
FAF_VERSION="1.0.0"

faf_init_dirs() {
  mkdir -p "$FAF_DATA/logs" "$FAF_STATE_DIR" "$FAF_PROFILES_DIR" 2>/dev/null
  [ -f "$FAF_CONFIG_FILE" ] || {
    if [ -f "$FAF_DIR_DEFAULT_CONFIG" ]; then cp -f "$FAF_DIR_DEFAULT_CONFIG" "$FAF_CONFIG_FILE"
    elif [ -f "$MODPATH/config.conf" ]; then cp -f "$MODPATH/config.conf" "$FAF_CONFIG_FILE"; fi
  }
  [ -f "$FAF_TARGET_FILE" ] || {
    if [ -f "$FAF_DIR_DEFAULT_TARGET" ]; then cp -f "$FAF_DIR_DEFAULT_TARGET" "$FAF_TARGET_FILE"
    elif [ -f "$MODPATH/target.list" ]; then cp -f "$MODPATH/target.list" "$FAF_TARGET_FILE"
    else echo "# Faa App Freezer targets" > "$FAF_TARGET_FILE"; fi
  }
  # profil bawaan
  [ -f "$FAF_PROFILES_DIR/default.conf" ] || echo "# default profile (ikuti config.conf)" > "$FAF_PROFILES_DIR/default.conf" 2>/dev/null
  [ -f "$FAF_PROFILES_DIR/gaming.conf" ] || {
    echo "AUTO_FREEZE=true" > "$FAF_PROFILES_DIR/gaming.conf" 2>/dev/null
    echo "FREEZE_DELAY=30" >> "$FAF_PROFILES_DIR/gaming.conf" 2>/dev/null
  }
}

faf_load_backend() {
  _base="$MODPATH/common"
  [ -d "$_base" ] || _base="$(dirname "$0")/../common"
  # shell Android: source satu per satu, abaikan yang hilang dengan pesan jelas
  # shellcheck disable=SC1090
  for _f in logger.sh config.sh package.sh freeze.sh target.sh; do
    if [ -f "$_base/$_f" ]; then . "$_base/$_f"
    elif [ -f "$MODPATH/$_f" ]; then . "$MODPATH/$_f"
    else echo "faf: backend hilang: $_f" >&2; return 1; fi
  done
  faf_init_dirs
  faf_config_load
}

faf_require_root() {
  if [ "$(id -u 2>/dev/null)" != "0" ]; then
    echo "faf butuh root (jalankan via su -c 'faf ...')" >&2
    return 1
  fi
}
