package com.faa.faf;

import android.app.Activity;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.Switch;
import android.widget.TextView;
import android.widget.Toast;

/** Dashboard utama: status, auto-freeze, delay, apply, log, navigasi. */
public class MainActivity extends Activity {
    TextView tvRoot, tvStats, tvLog;
    Switch swAuto;
    Button btnDelay, btnApply;

    @Override protected void onCreate(Bundle b) {
        super.onCreate(b);
        setContentView(R.layout.activity_main);
        tvRoot = findViewById(R.id.tvRoot);
        tvStats = findViewById(R.id.tvStats);
        tvLog = findViewById(R.id.tvLog);
        swAuto = findViewById(R.id.swAuto);
        btnDelay = findViewById(R.id.btnDelay);
        btnApply = findViewById(R.id.btnApply);

        findViewById(R.id.navApps).setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) { startActivity(new Intent(MainActivity.this, AppListActivity.class)); }
        });
        findViewById(R.id.navSettings).setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) { startActivity(new Intent(MainActivity.this, SettingsActivity.class)); }
        });
        findViewById(R.id.navTargets).setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                Intent i = new Intent(MainActivity.this, AppListActivity.class);
                i.putExtra("filter", "target");
                startActivity(i);
            }
        });
        btnApply.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) { bg(new Bg() { public String run() { return FafBridge.apply().out; } }, "applied"); }
        });
        btnDelay.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) { cycleDelay(); }
        });
        swAuto.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                final boolean on = swAuto.isChecked();
                bg(new Bg() { public String run() { return FafBridge.auto(on ? "on" : "off").out; } }, on ? "auto ON" : "auto OFF");
            }
        });
    }

    @Override protected void onResume() { super.onResume(); refresh(); }

    void refresh() {
        tvRoot.setText("● checking…");
        bg(new Bg() {
            public String run() {
                boolean root = FafBridge.hasRoot();
                String st = FafBridge.status().out;
                String cfg = FafBridge.configShow().out;
                String logs = FafBridge.logs().out;
                return (root ? "ROOT|" : "NOROOT|") + st + "\n---\n" + cfg + "\n---LOG tail---\n" + tail(logs, 12);
            }
        }, null);
    }

    static String tail(String s, int n) {
        if (s == null) return "";
        String[] ls = s.split("\n");
        StringBuilder sb = new StringBuilder();
        for (int i = Math.max(0, ls.length - n); i < ls.length; i++) sb.append(ls[i]).append("\n");
        return sb.toString();
    }

    void cycleDelay() {
        // 30 -> 60 -> 180 -> 300 -> 30
        bg(new Bg() {
            public String run() {
                String cfg = FafBridge.configShow().out;
                int cur = 60;
                try {
                    for (String l : cfg.split("\n"))
                        if (l.startsWith("FREEZE_DELAY=")) cur = Integer.parseInt(l.substring(13).trim());
                } catch (Exception ignored) {}
                int next = cur <= 30 ? 60 : cur <= 60 ? 180 : cur <= 180 ? 300 : 30;
                return FafBridge.configSet("FREEZE_DELAY", String.valueOf(next)).out;
            }
        }, "delay updated");
    }

    interface Bg { String run(); }

    void bg(final Bg job, final String toast) {
        new AsyncTask<Void, Void, String>() {
            protected String doInBackground(Void... v) {
                try { return job.run(); } catch (Exception e) { return e.toString(); }
            }
            protected void onPostExecute(String out) {
                if (out == null) out = "";
                boolean root = out.startsWith("ROOT|");
                String body = out.startsWith("ROOT|") || out.startsWith("NOROOT|") ? out.substring(out.indexOf('|') + 1) : out;
                if (out.startsWith("ROOT|") || out.startsWith("NOROOT|")) {
                    tvRoot.setText(root ? "● ROOT AVAILABLE" : "● ROOT MISSING");
                    tvRoot.setTextColor(root ? 0xFF2E9E6B : 0xFFE65100);
                    String[] parts = body.split("\n---\n");
                    tvStats.setText(parts.length > 0 ? parts[0] : body);
                    String delay = "60";
                    if (parts.length > 1) for (String l : parts[1].split("\n"))
                        if (l.startsWith("FREEZE_DELAY=")) delay = l.substring(13).trim();
                    btnDelay.setText("⏱ " + delay + "s");
                    swAuto.setChecked(parts.length > 1 && parts[1].contains("AUTO_FREEZE=true"));
                    if (parts.length > 2) tvLog.setText(parts[2]);
                } else {
                    if (toast != null) Toast.makeText(MainActivity.this, toast + ": " + body, Toast.LENGTH_SHORT).show();
                    refreshLite();
                }
            }
        }.execute();
    }

    void refreshLite() {
        new AsyncTask<Void, Void, String>() {
            protected String doInBackground(Void... v) { return FafBridge.logs().out; }
            protected void onPostExecute(String s) { tvLog.setText(MainActivity.tail(s, 14)); }
        }.execute();
    }
}
