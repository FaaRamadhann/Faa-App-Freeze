#!/system/bin/sh
# FAF action.sh - Tombol Action di Magisk Manager
# Menampilkan status + toggle cepat auto-freeze bisa via volume keys bila tersedia.
MODDIR=${0%/*}
. "$MODDIR/common/core.sh"
faf_load_backend >/dev/null 2>&1

echo "=== Faa App Freezer ==="
echo "apps:    $(pm list packages 2>/dev/null | wc -l | tr -d ' ')"
echo "frozen:  $(pm list packages -d 2>/dev/null | wc -l | tr -d ' ')"
echo "targets: $(faf_target_list 2>/dev/null | wc -l | tr -d ' ')"
echo "auto:    $AUTO_FREEZE (${FREEZE_DELAY}s)"
_p="$(cat "$FAF_STATE_DIR/daemon.pid" 2>/dev/null)"
if [ -n "$_p" ] && kill -0 "$_p" 2>/dev/null; then echo "daemon:  running (pid $_p)"; else echo "daemon:  stopped"; fi
echo ""
echo "Kelola via terminal: su -c 'faf status'"
echo "atau buka aplikasi FAF Manager."
echo "Log: $FAF_LOG_FILE"
exit 0
