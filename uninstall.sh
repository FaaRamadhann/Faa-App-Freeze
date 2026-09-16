#!/sbin/sh
# FAF uninstall.sh - Cleanup saat module di-uninstall
# Penting: cairkan dulu app yang dibekukan FAF agar tidak tertinggal disabled.

MODDIR=${0%/*}
# core bisa gagal bila file sudah terhapus; buat protektif
if [ -f "$MODDIR/common/core.sh" ]; then
  . "$MODDIR/common/core.sh"
  faf_load_backend >/dev/null 2>&1 || true
fi

FAF_DATA=${FAF_DATA:-/data/adb/faf}

# 1. cairkan semua managed (berdasar target.list)
if [ -f "$FAF_DATA/target.list" ] && command -v pm >/dev/null 2>&1; then
  while IFS= read -r _line || [ -n "$_line" ]; do
    case "$_line" in ''|\#*) continue ;; esac
    _pkg="$(echo "$_line" | cut -d: -f1 | tr -d ' ')"
    [ -z "$_pkg" ] && continue
    pm unsuspend --user 0 "$_pkg" >/dev/null 2>&1
    pm enable "$_pkg" >/dev/null 2>&1
    pm enable --user 0 "$_pkg" >/dev/null 2>&1
  done < "$FAF_DATA/target.list"
fi

# 2. stop daemon
if [ -f "$FAF_DATA/state/daemon.pid" ]; then
  kill "$(cat "$FAF_DATA/state/daemon.pid" 2>/dev/null)" 2>/dev/null
  rm -f "$FAF_DATA/state/daemon.pid"
fi
rm -rf "$FAF_DATA/state/pending" "$FAF_DATA/state/pending_"* 2>/dev/null

# 3. runtime /data/adb/faf dibiarkan (config + target + log user) agar
#    install ulang tidak kehilangan data. Hapus manual bila mau bersih:
#    rm -rf /data/adb/faf
# NOTE: Magisk otomatis menghapus $MODDIR (/data/adb/modules/faafreeze).

exit 0
