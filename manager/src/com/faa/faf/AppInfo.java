package com.faa.faf;

/** Model informasi aplikasi untuk ListView / detail. */
public class AppInfo {
    public String label;
    public String pkg;
    public String version;
    public boolean system;
    public boolean frozen;
    public boolean target;

    public AppInfo(String label, String pkg) {
        this.label = label;
        this.pkg = pkg;
    }

    @Override public String toString() { return label + " (" + pkg + ")"; }
}
