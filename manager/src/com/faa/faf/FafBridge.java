package com.faa.faf;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;

/** Bridge APK -> CLI faf. Satu-satunya jalan freeze (single backend). */
public class FafBridge {
    public static class Result {
        public final int code;
        public final String out;
        Result(int c, String o) { code = c; out = o; }
        public boolean ok() { return code == 0; }
    }

    public static String readStream(InputStream in) {
        try {
            ByteArrayOutputStream bos = new ByteArrayOutputStream();
            byte[] buf = new byte[4096];
            int n;
            while ((n = in.read(buf)) > 0) bos.write(buf, 0, n);
            return new String(bos.toByteArray(), "UTF-8");
        } catch (Exception e) { return ""; }
    }

    /** Jalankan `su -c "faf ..."`, fallback `sh -c` bila su gagal (mode baca saja). */
    public static Result run(String fafArgs) {
        String[] suCmd = {"su", "-c", "faf " + fafArgs};
        try {
            Process p = Runtime.getRuntime().exec(suCmd);
            String out = readStream(p.getInputStream()) + readStream(p.getErrorStream());
            int rc = p.waitFor();
            if (rc == 0 || !out.trim().isEmpty()) return new Result(rc, out.trim());
        } catch (Exception ignored) {}
        // fallback tanpa root (hanya untuk status baca)
        try {
            Process p = Runtime.getRuntime().exec(new String[]{"sh", "-c", "faf " + fafArgs});
            String out = readStream(p.getInputStream()) + readStream(p.getErrorStream());
            return new Result(p.waitFor(), out.trim());
        } catch (Exception e) {
            return new Result(1, e.toString());
        }
    }

    public static boolean hasRoot() {
        Result r = run("version");
        // valid bila CLI menjawab walau tanpa root pun; cek su biner:
        try {
            Process p = Runtime.getRuntime().exec(new String[]{"su", "-c", "id -u"});
            String o = readStream(p.getInputStream()).trim();
            p.waitFor();
            return o.equals("0");
        } catch (Exception e) { return false; }
    }

    public static Result freeze(String pkg)   { return run("freeze " + pkg); }
    public static Result unfreeze(String pkg) { return run("unfreeze " + pkg); }
    public static Result toggle(String pkg)   { return run("toggle " + pkg); }
    public static Result status()   { return run("status"); }
    public static Result apply()    { return run("apply"); }
    public static Result logs()     { return run("logs"); }
    public static Result clearLogs(){ return run("clog"); }
    public static Result targets()  { return run("target ls"); }
    public static Result targetAdd(String pkg) { return run("target add " + pkg); }
    public static Result targetRm(String pkg)  { return run("target rm " + pkg); }
    public static Result configShow() { return run("config show"); }
    public static Result configSet(String k, String v) { return run("config set " + k + " " + v); }
    public static Result auto(String sub) { return run("auto " + sub); }
}
