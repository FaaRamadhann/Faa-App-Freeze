package com.faa.faf;

import android.app.Activity;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.View;
import android.widget.Toast;

/** Pengaturan: auto-freeze, delay, metode, versi, clear logs, reset. */
public class SettingsActivity extends Activity {
    @Override protected void onCreate(Bundle b) {
        super.onCreate(b);
        setContentView(R.layout.activity_settings);
        click(R.id.btnAuto, "auto", new Op() { public String run() {
            String cfg = FafBridge.configShow().out;
            boolean on = cfg.contains("AUTO_FREEZE=true");
            return FafBridge.auto(on ? "off" : "on").out;
        } });
        click(R.id.btnDelay, "delay", new Op() { public String run() {
            return FafBridge.configSet("FREEZE_DELAY", "60").out;
        } });
        click(R.id.btnMethod, "method", new Op() { public String run() {
            String cfg = FafBridge.configShow().out;
            boolean dis = !cfg.contains("FREEZE_METHOD=suspend");
            return FafBridge.configSet("FREEZE_METHOD", dis ? "suspend" : "disable").out;
        } });
        click(R.id.btnVer, "version", new Op() { public String run() { return FafBridge.run("version").out; } });
        click(R.id.btnClearLogs, "logs", new Op() { public String run() { return FafBridge.clearLogs().out; } });
        click(R.id.btnReset, "reset", new Op() { public String run() { return FafBridge.run("config reset").out; } });
        findViewById(R.id.btnBack).setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) { finish(); }
        });
    }

    interface Op { String run(); }

    void click(int id, final String tag, final Op op) {
        findViewById(id).setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                new AsyncTask<Void, Void, String>() {
                    protected String doInBackground(Void... x) {
                        try { return op.run(); } catch (Exception e) { return e.toString(); }
                    }
                    protected void onPostExecute(String s) {
                        Toast.makeText(SettingsActivity.this, tag + ": " + s, Toast.LENGTH_SHORT).show();
                    }
                }.execute();
            }
        });
    }
}
