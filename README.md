# Faa App Freeze (FAF) ❄️

Pembeku aplikasi root mirip [Hail](https://f-droid.org/packages/com.aistra.hail/) — via **Magisk module + CLI `faf` + FAF Manager APK** dengan tema **Light Blue Sea** 🌊.

APK cuma control panel. Engine-nya adalah `faf` CLI + `common/*.sh` + Android Package Manager. Satu backend, satu sumber kebenaran.

## Fitur

- `faf freeze / unfreeze / toggle <package>` (via `pm disable-user`, fallback `pm suspend`)
- `target.list` persisten (`faf target add/rm/ls/clear`, `faf apply`, `faf reset`)
- Auto-freeze daemon saat boot (pantau foreground, timer default 60 dtk, cancel bila app dibuka lagi)
- `faf status / list / info / config / logs / clog / auto`
- FAF Manager APK: Dashboard, daftar App (All/User/System/Frozen + search), Targets, Settings, Logs (minSdk 21, targetSdk 34)
- Uninstall aman: semua app kelolaan FAF di-unfreeze dulu

## Struktur

```
META-INF/com/google/android/  update-binary, updater-script
system/bin/faf                CLI utama
common/                       core, package, freeze, target, config, logger
config/                       config.conf + target.list default
service.sh action.sh customize.sh uninstall.sh
manager/                      source APK (javac+d8+aapt, tanpa Android Studio)
module.prop zip.py
```

Runtime setelah install: `/data/adb/faf/` (config.conf, target.list, profiles/, logs/faf.log, state/)

## Cara Install

Ada dua cara: **via PC (Windows/Linux)** atau **via Termux di HP**.

### A. Via PC (Windows / Linux) — pakai `adb push`

**Langkah 0 — Siapkan (clone + pack zip):**

Prasyarat: sudah ada `git` dan `python 3` (versi apa pun) di PC.

```
# 1. Clone repo ini
git clone https://github.com/FaaRamadhann/Faa-App-Freeze.git
cd Faa-App-Freeze

# 2. (Opsional) Build FAF Manager APK — butuh JDK 17+ dan Android SDK,
#    sesuaikan path di manager/build.py (BUILD_TOOLS, ANDROID_JAR, JAVA_HOME)
python manager/build.py
# Hasil: manager/build/FAF-Manager.apk (otomatis disalin jadi manager.apk)

# 3. Pack jadi zip
python zip.py
```

Perintah `python zip.py` menghasilkan file:

```
build/FAF-v1.0.0.zip
```

> Tanpa `manager.apk`, zip tetap bisa di-flash — cuma FAF Manager tidak
> auto-install (bisa install manual dari `manager/build/FAF-Manager.apk`).

**Langkah 1 — Hubungkan HP ke PC:**

Aktifkan **USB Debugging** di HP (Developer Options), lalu colok USB
(atau `adb connect IP:5555` untuk wireless debugging).

```
# Cek HP terdeteksi
adb devices
# Harus muncul status "device"
```

**Langkah 2 — Push zip ke HP:**

```
adb push build/FAF-v1.0.0.zip /sdcard/
```

**Langkah 3 — Install lewat manager root (dari HP):**

Buka aplikasi **Magisk / KernelSU / APatch** → **Modul** → **Install dari penyimpanan** → pilih `FAF-v1.0.0.zip`.

Atau via terminal/shell (root):

```
# masuk shell adb
adb shell
# lalu jalankan sebagai root (sesuaikan manager root!)
su -c 'magisk --install-module /sdcard/FAF-v1.0.0.zip'
```

**Langkah 4 — Reboot**, lalu cek dari PC:

```
adb shell su -c 'faf status'
# Harus muncul: FAF v1.0.0, apps, frozen, targets, daemon
```

---

### B. Via Termux (di HP, tanpa PC)

Prasyarat: sudah ada **Termux** dan akses **root** (`su`).

**Langkah 1 — Install git & clone:**

```
pkg install -y git python
git clone https://github.com/FaaRamadhann/Faa-App-Freeze.git
cd Faa-App-Freeze
```

**Langkah 2 — Build zip:**

```
python zip.py
```

> Build APK Manager (`manager/build.py`) butuh JDK + Android SDK,
> jadi di Termux lewati saja — zip tetap jadi tanpa `manager.apk`,
> atau download APK dari GitHub Releases bila tersedia.

**Langkah 3 — Pindahkan zip ke penyimpanan (agar bisa dipilih manager):**

```
cp build/FAF-v*.zip /sdcard/
```

**Langkah 4 — Install via manager root:**

Buka aplikasi **Magisk / KernelSU / APatch** → **Modul** → **Install dari penyimpanan** → pilih zip.

Atau lewat Termux dengan root:

```
su -c 'magisk --install-module /sdcard/FAF-v*.zip'
```

**Langkah 5 — Reboot**, lalu cek:

```
su -c 'faf status'
```

---

## Pakai CLI

```sh
su -c 'faf status'
su -c 'faf list frozen'
su -c 'faf freeze com.google.android.youtube'
su -c 'faf unfreeze com.termux'
su -c 'faf target add com.android.chrome'
su -c 'faf apply'
su -c 'faf config set FREEZE_DELAY 60'
su -c 'faf logs'
```

> ⚠️ Jangan freeze aplikasi kritikal sistem seperti keyboard
> (`com.android.inputmethod.latin`) — bisa bikin HP tidak bisa ngetik.

## Uninstall

`uninstall.sh` mencairkan semua target FAF, menghentikan daemon,
membersihkan state. `/data/adb/faf` (config/log) sengaja dipertahankan —
hapus manual bila mau bersih total.

## Lisensi

MIT — lihat `LICENSE`.
