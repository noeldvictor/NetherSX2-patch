package xyz.aethersx2.android;

import android.app.Activity;
import android.content.SharedPreferences;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;
import java.util.Locale;
import java.util.Map;

public final class ThorPerformanceActivity extends Activity {
    private static final String PREFS_NAME = "xyz.aethersx2.android_preferences";

    private SharedPreferences prefs;
    private TextView status;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        buildUi();
        refreshStatus();
    }

    private void buildUi() {
        ScrollView scroll = new ScrollView(this);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        int pad = dp(18);
        root.setPadding(pad, pad, pad, pad);
        scroll.addView(root);

        TextView title = new TextView(this);
        title.setText("Thor Performance Presets");
        title.setTextSize(22.0f);
        title.setPadding(0, 0, 0, dp(8));
        root.addView(title);

        TextView body = new TextView(this);
        body.setText("Apply gameplay-focused defaults for Thor. Restart the running game after changing presets.");
        body.setTextSize(15.0f);
        body.setPadding(0, 0, 0, dp(14));
        root.addView(body);

        status = new TextView(this);
        status.setTextSize(14.0f);
        status.setPadding(0, 0, 0, dp(12));
        root.addView(status);

        addButton(root, "Apply Balanced", new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                applyBalanced();
            }
        });
        addButton(root, "Apply Fast", new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                applyFast();
            }
        });
        addButton(root, "Apply Accurate", new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                applyAccurate();
            }
        });
        addButton(root, "Apply Lite Conservative", new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                applyLite();
            }
        });

        setContentView(scroll);
    }

    private void addButton(LinearLayout root, String text, View.OnClickListener listener) {
        Button button = new Button(this);
        button.setText(text);
        button.setAllCaps(false);
        button.setOnClickListener(listener);
        root.addView(button);
    }

    private void applyBalanced() {
        SharedPreferences.Editor edit = prefs.edit();
        putCommonSpeed(edit);
        edit.putString("EmuCore/GS/upscale_multiplier", "1.500000");
        edit.putString("EmuCore/GS/accurate_blending_unit", "1");
        edit.putString("EmuCore/GS/HWDownloadMode", "1");
        edit.putBoolean("EmuCore/GS/SkipDuplicateFrames", false);
        edit.apply();
        applied("Balanced");
    }

    private void applyFast() {
        SharedPreferences.Editor edit = prefs.edit();
        putCommonSpeed(edit);
        edit.putString("EmuCore/GS/upscale_multiplier", "1.000000");
        edit.putString("EmuCore/GS/accurate_blending_unit", "0");
        edit.putString("EmuCore/GS/HWDownloadMode", "1");
        edit.putBoolean("EmuCore/GS/SkipDuplicateFrames", true);
        edit.apply();
        applied("Fast");
    }

    private void applyAccurate() {
        SharedPreferences.Editor edit = prefs.edit();
        putCommonSpeed(edit);
        edit.putString("EmuCore/GS/upscale_multiplier", "1.000000");
        edit.putString("EmuCore/GS/accurate_blending_unit", "1");
        edit.putString("EmuCore/GS/HWDownloadMode", "0");
        edit.putBoolean("EmuCore/GS/SkipDuplicateFrames", false);
        edit.apply();
        applied("Accurate");
    }

    private void applyLite() {
        SharedPreferences.Editor edit = prefs.edit();
        putCommonSpeed(edit);
        edit.putString("EmuCore/AffinityControlMode", "0");
        edit.putBoolean("EmuCore/Speedhacks/vuThread", false);
        edit.putString("EmuCore/GS/upscale_multiplier", "1.000000");
        edit.putString("EmuCore/GS/accurate_blending_unit", "1");
        edit.putString("EmuCore/GS/HWDownloadMode", "0");
        edit.putBoolean("EmuCore/GS/SkipDuplicateFrames", false);
        edit.apply();
        applied("Lite Conservative");
    }

    private void putCommonSpeed(SharedPreferences.Editor edit) {
        edit.putString("EmuCore/GS/Renderer", "14");
        edit.putString("EmuCore/AffinityControlMode", "7");
        edit.putBoolean("EmuCore/Speedhacks/vuThread", true);
        edit.putBoolean("EmuCore/Speedhacks/vu1Instant", true);
        edit.putBoolean("EmuCore/CPU/Recompiler/EnableEE", true);
        edit.putBoolean("EmuCore/CPU/Recompiler/EnableVU0", true);
        edit.putBoolean("EmuCore/CPU/Recompiler/EnableVU1", true);
        edit.putBoolean("EmuCore/CPU/Recompiler/EnableIOP", true);
        edit.putBoolean("EmuCore/CPU/Recompiler/EnableFastmem", true);
        edit.putBoolean("EmuCore/Speedhacks/vuFlagHack", true);
        edit.putBoolean("EmuCore/Speedhacks/WaitLoop", true);
        edit.putBoolean("EmuCore/Speedhacks/IntcStat", true);
        edit.putBoolean("EmuCore/GS/VsyncEnable", false);
        edit.putBoolean("EmuCore/GS/SyncToHostRefreshRate", false);
        edit.putBoolean("EmuCore/GS/DisableThreadedPresentation", false);
        edit.putBoolean("Logging/EnableFileLogging", false);
        edit.putBoolean("Logging/EnableSystemConsole", false);
        edit.putBoolean("Logging/EnableEEConsole", false);
        edit.putBoolean("Logging/EnableIOPConsole", false);
        edit.putBoolean("EmuCore/CdvdVerboseReads", false);
        edit.putBoolean("EmuCore/GS/UseDebugDevice", false);
        edit.putString("EmuCore/Speedhacks/EECycleRate", "0");
        edit.putString("EmuCore/Speedhacks/EECycleSkip", "0");
        edit.putString("EmuCore/GS/MaxAnisotropy", "0");
        edit.putString("EmuCore/GS/texture_preloading", "2");
    }

    private void applied(String name) {
        refreshStatus();
        Toast.makeText(this, name + " preset applied. Restart the game.", Toast.LENGTH_LONG).show();
    }

    private void refreshStatus() {
        status.setText(String.format(Locale.US,
                "Device: %s / %s\nRenderer: %s\nAffinity: %s\nMTVU: %s\nUpscale: %s\nReadbacks: %s\nBlending: %s\nDuplicate-frame skip: %s",
                Build.MODEL,
                Build.HARDWARE,
                rendererName(getString("EmuCore/GS/Renderer", "12")),
                affinityName(getString("EmuCore/AffinityControlMode", "0")),
                getBoolean("EmuCore/Speedhacks/vuThread", false) ? "On" : "Off",
                getString("EmuCore/GS/upscale_multiplier", "1.000000"),
                readbackName(getString("EmuCore/GS/HWDownloadMode", "0")),
                blendingName(getString("EmuCore/GS/accurate_blending_unit", "1")),
                getBoolean("EmuCore/GS/SkipDuplicateFrames", false) ? "On" : "Off"));
    }

    private String getString(String key, String fallback) {
        Map<String, ?> values = prefs.getAll();
        Object value = values.get(key);
        return value == null ? fallback : String.valueOf(value);
    }

    private boolean getBoolean(String key, boolean fallback) {
        Map<String, ?> values = prefs.getAll();
        Object value = values.get(key);
        if (value instanceof Boolean) {
            return ((Boolean) value).booleanValue();
        }
        if (value instanceof String) {
            return Boolean.parseBoolean((String) value);
        }
        return fallback;
    }

    private String rendererName(String value) {
        if ("14".equals(value)) {
            return "Vulkan";
        }
        if ("13".equals(value)) {
            return "Software";
        }
        return "OpenGL";
    }

    private String affinityName(String value) {
        if ("7".equals(value)) {
            return "Performance Cores";
        }
        if ("0".equals(value)) {
            return "Disabled";
        }
        return value;
    }

    private String readbackName(String value) {
        if ("1".equals(value)) {
            return "Fast";
        }
        if ("2".equals(value)) {
            return "Unsync";
        }
        if ("3".equals(value)) {
            return "Ignored";
        }
        return "Accurate";
    }

    private String blendingName(String value) {
        if ("0".equals(value)) {
            return "Minimum";
        }
        if ("2".equals(value)) {
            return "Medium";
        }
        return "Basic";
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }
}
