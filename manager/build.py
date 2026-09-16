"""
build.py - Build FAF-Manager.apk tanpa Android Studio (javac + d8 + aapt).
Basis: https://raw.githubusercontent.com/FaaRamadhann/Example-Build/refs/heads/main/ex-build.py

Cara pakai:
    python build.py                 # build dari folder manager/
    python build.py <path-manager>

Butuh: JDK 17+, Android SDK build-tools + platform android.jar.
Hasil: build/FAF-Manager.apk (zipalign + signed). Copy ke root sebagai
manager.apk sebelum pack zip Magisk (atau biarkan zip.py mengambilnya
dari manager/build/ otomatis bila diaktifkan).
"""

import os
import shutil
import subprocess
import sys

# ---------------- KONFIG ----------------
APP_NAME = "FAF-Manager"
MIN_SDK = "21"
TARGET_SDK = "34"
BUILD_TOOLS = r"C:\AndroidSDK\build-tools\35.0.0"
ANDROID_JAR = r"C:\AndroidSDK\platforms\android-34\android.jar"
JAVA_HOME = r"C:\Program Files\Java\jdk-21.0.10"
KEYSTORE = "debug.keystore"
KEY_ALIAS = "faf"
STOREPASS = "android"
KEYPASS = "android"
# -------------- akhir KONFIG ------------


def run(cmd, cwd):
    print("  $", " ".join(cmd))
    r = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if r.returncode != 0:
        print((r.stdout or "")[-2000:])
        print((r.stderr or "")[-2000:])
        sys.exit("GAGAL (rc=%d): %s" % (r.returncode, cmd[0]))
    return r


def main():
    root = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else ".")
    for must in ("AndroidManifest.xml", "src"):
        if not os.path.exists(os.path.join(root, must)):
            sys.exit("Bukan project Android: %s tidak ada di %s" % (must, root))

    javac = os.path.join(JAVA_HOME, "bin", "javac.exe")
    keytool = os.path.join(JAVA_HOME, "bin", "keytool.exe")
    d8 = os.path.join(BUILD_TOOLS, "d8.bat")
    aapt = os.path.join(BUILD_TOOLS, "aapt.exe")
    zipalign = os.path.join(BUILD_TOOLS, "zipalign.exe")
    apksigner = os.path.join(BUILD_TOOLS, "apksigner.bat")
    build = os.path.join(root, "build")
    gen = os.path.join(build, "gen")
    obj = os.path.join(build, "obj")
    dex = os.path.join(build, "dex")
    for d in (gen, obj, dex):
        os.makedirs(d, exist_ok=True)

    print("[1/7] kumpulkan source...")
    sources = []
    for dp, _, fns in os.walk(os.path.join(root, "src")):
        sources += [os.path.join(dp, f) for f in fns if f.endswith(".java")]
    if not sources:
        sys.exit("Tidak ada file .java di src/")
    print("  %d file java" % len(sources))

    print("[2/7] aapt generate R.java...")
    cmd = [aapt, "package", "-f", "-M", "AndroidManifest.xml"]
    if os.path.isdir(os.path.join(root, "res")):
        cmd += ["-S", "res"]
    cmd += ["-I", ANDROID_JAR, "-m", "-J", gen]
    run(cmd, root)
    r_java = []
    for dp, _, fns in os.walk(gen):
        r_java += [os.path.join(dp, f) for f in fns if f.endswith(".java")]
    print("  R.java: %d" % len(r_java))

    print("[3/7] javac...")
    with open(os.path.join(build, "sources.txt"), "w") as fh:
        fh.write("\n".join(sources + r_java))
    run([javac, "--release", "8", "-classpath", ANDROID_JAR,
         "-d", obj, "@" + os.path.join(build, "sources.txt")], root)

    print("[4/7] d8 (java -> dex)...")
    classes = []
    for dp, _, fns in os.walk(obj):
        classes += [os.path.join(dp, f) for f in fns if f.endswith(".class")]
    run([d8, "--min-api", MIN_SDK, "--lib", ANDROID_JAR,
         "--output", dex] + classes, root)

    print("[5/7] aapt package + add classes.dex...")
    cmd = [aapt, "package", "-f", "-M", "AndroidManifest.xml"]
    if os.path.isdir(os.path.join(root, "res")):
        cmd += ["-S", "res"]
    cmd += ["-I", ANDROID_JAR, "-F", os.path.join(build, "unsigned.apk")]
    run(cmd, root)
    run([aapt, "add", os.path.join(build, "unsigned.apk"), "classes.dex"], dex)

    print("[6/7] keystore (sekali saja)...")
    print("  PENTING: backup debug.keystore - update APK wajib key yang sama!")
    ks = os.path.join(root, KEYSTORE)
    if not os.path.exists(ks):
        run([keytool, "-genkeypair", "-keystore", ks, "-alias", KEY_ALIAS,
             "-keyalg", "RSA", "-keysize", "2048", "-validity", "10950",
             "-storepass", STOREPASS, "-keypass", KEYPASS,
             "-dname", "CN=FAF"], root)

    print("[7/7] zipalign + apksigner...")
    run([zipalign, "-f", "4", os.path.join(build, "unsigned.apk"),
         os.path.join(build, "aligned.apk")], root)
    out_apk = os.path.join(build, "%s.apk" % APP_NAME)
    run([apksigner, "sign", "--ks", ks, "--ks-key-alias", KEY_ALIAS,
         "--ks-pass", "pass:%s" % STOREPASS, "--key-pass", "pass:%s" % KEYPASS,
         "--out", out_apk, os.path.join(build, "aligned.apk")], root)
    run([apksigner, "verify", out_apk], root)

    # copy ke root module sebagai manager.apk agar customize.sh bisa install
    try:
        root_module = os.path.dirname(root)
        if os.path.isfile(os.path.join(root_module, "module.prop")):
            shutil.copyfile(out_apk, os.path.join(root_module, "manager.apk"))
            print("  disalin -> manager.apk (root module)")
    except Exception as e:
        print("  skip copy manager.apk: %s" % e)

    print("\nSELESAI: %s" % out_apk)


if __name__ == "__main__":
    main()
