#!/system/bin/sh
# FAF service.sh - Boot service & auto-freeze daemon
# Magisk late_start service. Alur: tunggu boot -> apply target -> daemon (opsional)

MODDIR=${0%/*}

# mode daemon dipanggil dari CLI: service.sh daemon
if [ "$1" = "daemon" ]; then
  DAEMON_MODE=true
else
  DAEMON_MODE=false
fi

. "$MODDIR/common/core.sh"
faf_load_backend || exit 1

# ---------- helpers daemon ----------
faf_current_app() {
  # cara ringan tanpa dumpsys berat: am stack / activity resolver
  dumpsys activity activities 2>/dev/null | grep -m1 "mFocusedApp" | sed 's/.* \([^ ]*\/[^ }]*\).*/\1/' | cut -d/ -f1
}

faf_is_foreground() {
  # return 0 bila $1 sedang foreground
  [ "$(faf_current_app)" = "$1" ]
}

faf_daemon_loop() {
  echo "$$" > "$FAF_STATE_DIR/daemon.pid"
  log_info "auto-freeze daemon started (delay=${FREEZE_DELAY}s)"
  # pending timers: file state/pending_<pkg> berisi epoch deadline
  mkdir -p "$FAF_STATE_DIR/pending" 2>/dev/null
  while true; do
    faf_config_load
    if [ "$AUTO_FREEZE" != "true" ]; then
      sleep 15; continue
    fi
    _cur="$(faf_current_app)"
    echo "$_cur" > "$FAF_STATE_DIR/current_app" 2>/dev/null
    _now="$(date +%s 2>/dev/null || echo 0)"
    for _entry in $(faf_target_list 2>/dev/null); do
      _pkg="$(echo "$_entry" | cut -d: -f1)"
      [ -z "$_pkg" ] && continue
      faf_pkg_exists "$_pkg" || continue
      faf_is_frozen "$_pkg" && { rm -f "$FAF_STATE_DIR/pending_${_pkg}" 2>/dev/null; continue; }
      if [ "$_cur" = "$_pkg" ]; then
        # app dibuka -> cancel timer
        rm -f "$FAF_STATE_DIR/pending_${_pkg}" 2>/dev/null
      else
        # app tidak foreground
        if [ -f "$FAF_STATE_DIR/pending_${_pkg}" ]; then
          _deadline="$(cat "$FAF_STATE_DIR/pending_${_pkg}" 2>/dev/null)"
          case "$_deadline" in ''|*[!0-9]*) _deadline=$((_now + FREEZE_DELAY)) ;; esac
          if [ "$_now" -ge "$_deadline" ]; then
            # pastikan masih background (bukan sekadar glitch focus)
            sleep 3
            faf_is_foreground "$_pkg" && { rm -f "$FAF_STATE_DIR/pending_${_pkg}"; continue; }
            log_info "$_pkg auto-freeze (background ${FREEZE_DELAY}s)"
            faf_freeze "$_pkg" >/dev/null 2>&1
            rm -f "$FAF_STATE_DIR/pending_${_pkg}"
          fi
        else
          # start timer hanya bila app pernah terlihat? hemat: start untuk semua target
          # tapi hanya jika app benar-benar pernah running baru-baru ini (opsional).
          # Sederhana: start timer sekarang.
          echo $((_now + FREEZE_DELAY)) > "$FAF_STATE_DIR/pending_${_pkg}" 2>/dev/null
        fi
      fi
    done
    sleep 10
  done
}

# ---------- boot flow ----------
if [ "$DAEMON_MODE" = "true" ]; then
  faf_daemon_loop
  exit 0
fi

# tunggu boot selesai (maks ~5 menit)
for _i in $(seq 1 60); do
  if [ "$(getprop sys.boot_completed 2>/dev/null)" = "1" ]; then break; fi
  sleep 5
done
# tunggu package manager siap
for _i in $(seq 1 24); do
  pm list packages >/dev/null 2>&1 && break
  sleep 5
done

log_info "FAF service started"
echo "running" > "$FAF_STATE_DIR/status" 2>/dev/null

# terapkan target.list saat boot
faf_config_load
if [ "$APPLY_ON_BOOT" = "true" ]; then
  log_info "applying targets on boot"
  faf_apply_targets >/dev/null 2>&1
fi

# start daemon bila aktif
if [ "$AUTO_FREEZE" = "true" ]; then
  # bunuh daemon lama bila ada
  _old="$(cat "$FAF_STATE_DIR/daemon.pid" 2>/dev/null)"
  [ -n "$_old" ] && kill "$_old" 2>/dev/null
  nohup sh "$MODDIR/service.sh" daemon >/dev/null 2>&1 &
  log_info "auto-freeze daemon spawned"
else
  log_info "auto-freeze disabled, idle"
fi
