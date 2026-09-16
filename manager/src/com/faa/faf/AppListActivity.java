package com.faa.faf;

import android.app.Activity;
import android.os.AsyncTask;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;
import java.util.ArrayList;
import java.util.List;

/** Daftar aplikasi + filter All/User/System/Frozen + search + freeze/unfreeze + target. */
public class AppListActivity extends Activity {
    ListView lv;
    EditText etSearch;
    List<AppInfo> all = new ArrayList<AppInfo>();
    List<AppInfo> shown = new ArrayList<AppInfo>();
    String mode = "all";
    AppAdapter adapter;

    @Override protected void onCreate(Bundle b) {
        super.onCreate(b);
        setContentView(R.layout.activity_apps);
        lv = findViewById(R.id.lvApps);
        etSearch = findViewById(R.id.etSearch);
        adapter = new AppAdapter();
        lv.setAdapter(adapter);
        if (getIntent() != null && "target".equals(getIntent().getStringExtra("filter"))) mode = "target";

        findViewById(R.id.fAll).setOnClickListener(filter("all"));
        findViewById(R.id.fUser).setOnClickListener(filter("user"));
        findViewById(R.id.fSys).setOnClickListener(filter("sys"));
        findViewById(R.id.fFrozen).setOnClickListener(filter("frozen"));
        findViewById(R.id.btnBack).setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) { finish(); }
        });
        etSearch.addTextChangedListener(new TextWatcher() {
            public void beforeTextChanged(CharSequence s, int a, int b, int c) {}
            public void onTextChanged(CharSequence s, int a, int b, int c) { applyFilter(); }
            public void afterTextChanged(Editable s) {}
        });
    }

    View.OnClickListener filter(final String m) {
        return new View.OnClickListener() { public void onClick(View v) { mode = m; applyFilter(); } };
    }

    @Override protected void onResume() { super.onResume(); load(); }

    void load() {
        new AsyncTask<Void, Void, List<AppInfo>>() {
            protected List<AppInfo> doInBackground(Void... v) {
                try { return new AppManager(AppListActivity.this).loadAll(); }
                catch (Exception e) { return new ArrayList<AppInfo>(); }
            }
            protected void onPostExecute(List<AppInfo> r) { all = r; applyFilter(); }
        }.execute();
    }

    void applyFilter() {
        String q = etSearch.getText() != null ? etSearch.getText().toString().toLowerCase() : "";
        shown.clear();
        for (AppInfo a : all) {
            if ("user".equals(mode) && a.system) continue;
            if ("sys".equals(mode) && !a.system) continue;
            if ("frozen".equals(mode) && !a.frozen) continue;
            if ("target".equals(mode) && !a.target) continue;
            if (!q.isEmpty() && !(a.label.toLowerCase().contains(q) || a.pkg.toLowerCase().contains(q))) continue;
            shown.add(a);
        }
        adapter.notifyDataSetChanged();
        setTitle("Applications (" + shown.size() + ")");
    }

    class AppAdapter extends BaseAdapter {
        public int getCount() { return shown.size(); }
        public Object getItem(int p) { return shown.get(p); }
        public long getItemId(int p) { return p; }
        public View getView(final int pos, View cv, ViewGroup parent) {
            if (cv == null) cv = LayoutInflater.from(AppListActivity.this).inflate(R.layout.item_app, parent, false);
            final AppInfo a = shown.get(pos);
            ((TextView) cv.findViewById(R.id.tvName)).setText(a.label);
            ((TextView) cv.findViewById(R.id.tvPkg)).setText(a.pkg + "  ·  " + (a.system ? "system" : "user"));
            TextView st = cv.findViewById(R.id.tvState);
            st.setText(a.frozen ? "● FROZEN" : "● ACTIVE");
            st.setTextColor(a.frozen ? 0xFF0288D1 : 0xFF2E9E6B);
            Button bt = cv.findViewById(R.id.btnToggle);
            bt.setText(a.frozen ? "UNFREEZE" : "FREEZE");
            bt.setOnClickListener(new View.OnClickListener() {
                public void onClick(View v) {
                    op(new Op() { public FafBridge.Result run() {
                        return a.frozen ? FafBridge.unfreeze(a.pkg) : FafBridge.freeze(a.pkg);
                    } });
                }
            });
            Button tg = cv.findViewById(R.id.btnTarget);
            tg.setText(a.target ? "REMOVE TARGET" : "ADD TO TARGET");
            tg.setOnClickListener(new View.OnClickListener() {
                public void onClick(View v) {
                    op(new Op() { public FafBridge.Result run() {
                        return a.target ? FafBridge.targetRm(a.pkg) : FafBridge.targetAdd(a.pkg);
                    } });
                }
            });
            return cv;
        }
    }

    interface Op { FafBridge.Result run(); }

    void op(final Op o) {
        new AsyncTask<Void, Void, FafBridge.Result>() {
            protected FafBridge.Result doInBackground(Void... v) {
                try { return o.run(); } catch (Exception e) { return new FafBridge.Result(1, e.toString()); }
            }
            protected void onPostExecute(FafBridge.Result r) {
                Toast.makeText(AppListActivity.this, r.out, Toast.LENGTH_SHORT).show();
                load();
            }
        }.execute();
    }
}
