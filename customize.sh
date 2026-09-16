#!/sbin/sh
# FAF customize.sh - Magisk installation script
# Dijalankan Magisk saat install module.zip

SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=false
LATESTARTSERVICE=true

ui_print "- Faa App Freezer v1.0.0"
ui_print "- by Faa Ramadhan"

# --- cek environment ---
if [ "$API" -lt 26 ]; then
  ui_print "! Android 8.0+ dibutuhkan (API $API terdeteksi)"
  abort "! Abort"
fi
if ! command -v pm >/dev/null 2>&1; then
  ui_print "! package manager tidak tersedia"
  abort "! Abort"
fi

# --- runtime persistent ---
FAF_DATA=/data/adb/faf
ui_print "- Menyiapkan $FAF_DATA"
mkdir -p "$FAF_DATA/logs" "$FAF_DATA/state" "$FAF_DATA/profiles"

# config: jangan overwrite milik user
if [ ! -f "$FAF_DATA/config.conf" ]; then
  cp -f "$MODPATH/config/config.conf" "$FAF_DATA/config.conf"
  ui_print "- config.conf default dipasang"
else
  ui_print "- config.conf user dipertahankan"
fi
if [ ! -f "$FAF_DATA/target.list" ]; then
  cp -f "$MODPATH/config/target.list" "$FAF_DATA/target.list"
  ui_print "- target.list default dipasang"
else
  ui_print "- target.list user dipertahankan"
fi
[ -f "$FAF_DATA/profiles/gaming.conf" ] || {
  echo "AUTO_FREEZE=true" > "$FAF_DATA/profiles/gaming.conf"
  echo "FREEZE_DELAY=30" >> "$FAF_DATA/profiles/gaming.conf"
}
[ -f "$FAF_DATA/profiles/default.conf" ] || echo "# default profile" > "$FAF_DATA/profiles/default.conf"

# --- permissions backend ---
set_perm_recursive "$MODPATH/system" 0 0 0755 0644
set_perm_recursive "$MODPATH/common" 0 0 0755 0644
set_perm "$MODPATH/system/bin/faf" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
set_perm "$MODPATH/customize.sh" 0 0 0755 2>/dev/null || true

# --- install / update FAF Manager APK ---
if [ -f "$MODPATH/manager.apk" ]; then
  ui_print "- Menginstall FAF Manager..."
  pm install -r "$MODPATH/manager.apk" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    ui_print "- FAF Manager terinstall"
  else
    ui_print "! pm install gagal (bisa install manual manager.apk)"
  fi
  # hapus apk dari MODPATH agar tidak dobel makan tempat? biarkan untuk reinstall
else
  ui_print "! manager.apk tidak ada di zip (bangun via manager/build.py dulu)"
fi

ui_print "- Selesai. Reboot lalu jalankan: su -c 'faf status'"
ui_print "- Manager: Faa App Freezer"
