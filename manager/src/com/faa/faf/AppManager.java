package com.faa.faf;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/** Query PackageManager + padukan state FAF (frozen/target dari CLI). */
public class AppManager {
    private final PackageManager pm;

    public AppManager(Context ctx) { pm = ctx.getPackageManager(); }

    public List<AppInfo> loadAll() {
        List<ApplicationInfo> pkgs = pm.getInstalledApplications(PackageManager.GET_META_DATA);
        Set<String> frozen = frozenSet();
        Set<String> targets = targetSet();
        List<AppInfo> out = new ArrayList<AppInfo>();
        for (ApplicationInfo a : pkgs) {
            String label;
            try { label = String.valueOf(pm.getApplicationLabel(a)); }
            catch (Exception e) { label = a.packageName; }
            AppInfo i = new AppInfo(label, a.packageName);
            i.system = (a.flags & ApplicationInfo.FLAG_SYSTEM) != 0;
            try {
                PackageInfo pi = pm.getPackageInfo(a.packageName, 0);
                i.version = pi.versionName != null ? pi.versionName : "-";
            } catch (Exception e) { i.version = "-"; }
            i.frozen = frozen.contains(a.packageName);
            i.target = targets.contains(a.packageName);
            out.add(i);
        }
        Collections.sort(out, new Comparator<AppInfo>() {
            public int compare(AppInfo x, AppInfo y) { return x.label.compareToIgnoreCase(y.label); }
        });
        return out;
    }

    private Set<String> frozenSet() {
        Set<String> s = new HashSet<String>();
        try {
            // pm list packages -d butuh shell; lewat FAF: faf list frozen
            FafBridge.Result r = FafBridge.run("list frozen");
            if (r.ok()) for (String l : r.out.split("\n")) {
                l = l.trim(); if (!l.isEmpty()) s.add(l);
            }
        } catch (Exception ignored) {}
        return s;
    }

    private Set<String> targetSet() {
        Set<String> s = new HashSet<String>();
        try {
            FafBridge.Result r = FafBridge.targets();
            if (r.ok()) for (String l : r.out.split("\n")) {
                l = l.trim(); if (l.isEmpty() || l.startsWith("#")) continue;
                int c = l.indexOf(':'); s.add(c > 0 ? l.substring(0, c).trim() : l);
            }
        } catch (Exception ignored) {}
        return s;
    }
}
