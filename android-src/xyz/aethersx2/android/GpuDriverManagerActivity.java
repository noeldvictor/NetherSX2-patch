package xyz.aethersx2.android;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.SharedPreferences;
import android.os.Build;
import android.os.Bundle;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

public final class GpuDriverManagerActivity extends Activity {
    private static final String DEFAULT_DRIVER_NAME = "Turnip v26.0.0 R8";
    private static final String DEFAULT_DRIVER_URL = "https://github.com/K11MCH1/AdrenoToolsDrivers/releases/download/v26.0.0-rc08/Turnip_v26.0.0_R8.zip";
    private static final String PREFS_NAME = "xyz.aethersx2.android_preferences";

    private TextView statusView;
    private Button downloadButton;
    private Button customButton;
    private Button systemButton;
    private SharedPreferences prefs;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        buildUi();
        refreshStatus();
    }

    private void buildUi() {
        int pad = dp(18);
        ScrollView scrollView = new ScrollView(this);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(pad, pad, pad, pad);
        scrollView.addView(root);

        TextView title = new TextView(this);
        title.setText("Custom GPU Driver");
        title.setTextSize(24.0f);
        title.setPadding(0, 0, 0, dp(8));
        root.addView(title);

        TextView body = new TextView(this);
        body.setText("Downloads a Turnip driver package, installs its Vulkan driver into private app storage, and enables it for the Vulkan renderer after a full emulator restart.");
        body.setTextSize(15.0f);
        body.setPadding(0, 0, 0, dp(14));
        root.addView(body);

        statusView = new TextView(this);
        statusView.setTextSize(14.0f);
        statusView.setPadding(0, 0, 0, dp(14));
        root.addView(statusView);

        downloadButton = addButton(root, "Download recommended Turnip");
        downloadButton.setOnClickListener(v -> download(DEFAULT_DRIVER_URL, DEFAULT_DRIVER_NAME));

        customButton = addButton(root, "Download from custom URL");
        customButton.setOnClickListener(v -> showCustomUrlDialog());

        systemButton = addButton(root, "Use system driver");
        systemButton.setOnClickListener(v -> useSystemDriver());

        setContentView(scrollView);
    }

    private Button addButton(LinearLayout root, String text) {
        Button button = new Button(this);
        button.setText(text);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT);
        lp.setMargins(0, dp(4), 0, dp(4));
        root.addView(button, lp);
        return button;
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }

    private File driverDir() {
        return new File(getFilesDir(), "gpu_drivers/current");
    }

    private File driverFile() {
        return new File(driverDir(), "libvulkan_freedreno.so");
    }

    private File enabledMarker() {
        return new File(driverDir(), "enabled");
    }

    private void refreshStatus() {
        File driver = driverFile();
        boolean installed = driver.isFile();
        boolean enabled = installed && enabledMarker().isFile();
        String name = prefs.getString("GPUDriver/Name", installed ? "Installed driver" : "None");
        String date = prefs.getString("GPUDriver/InstalledAt", "Never");
        String url = prefs.getString("GPUDriver/Url", DEFAULT_DRIVER_URL);

        StringBuilder sb = new StringBuilder();
        sb.append("Device: ").append(Build.MANUFACTURER).append(" ").append(Build.MODEL)
                .append(" / ").append(Build.HARDWARE).append('\n');
        sb.append("Active path: ").append(enabled ? "Custom Turnip" : "System GPU driver").append('\n');
        sb.append("Installed: ").append(installed ? name : "No custom driver installed").append('\n');
        sb.append("Installed at: ").append(date).append('\n');
        sb.append("Driver file: ").append(driver.getAbsolutePath()).append('\n');
        sb.append("Source: ").append(url).append('\n');
        sb.append("Log: /sdcard/Android/data/xyz.aethersx2.android/files/gpu_driver_shim.log");
        statusView.setText(sb.toString());
        setBusy(false);
    }

    private void setBusy(boolean busy) {
        downloadButton.setEnabled(!busy);
        customButton.setEnabled(!busy);
        systemButton.setEnabled(!busy);
    }

    private void setMessage(String message, boolean busy) {
        statusView.setText(message);
        setBusy(busy);
    }

    private void useSystemDriver() {
        File marker = enabledMarker();
        if (marker.isFile()) {
            marker.delete();
        }
        prefs.edit().putBoolean("GPUDriver/Enabled", false).apply();
        refreshStatus();
    }

    private void showCustomUrlDialog() {
        EditText input = new EditText(this);
        input.setSingleLine(true);
        input.setText(prefs.getString("GPUDriver/Url", DEFAULT_DRIVER_URL));
        input.setSelectAllOnFocus(true);
        new AlertDialog.Builder(this)
                .setTitle("Driver package URL")
                .setView(input)
                .setPositiveButton("Download", (dialog, which) -> {
                    String url = input.getText().toString().trim();
                    if (!url.isEmpty()) {
                        download(url, "Custom Turnip package");
                    }
                })
                .setNegativeButton("Cancel", null)
                .show();
    }

    private void download(String url, String label) {
        setMessage("Downloading " + label + "...\n\n" + url, true);
        new Thread(() -> {
            try {
                File zip = new File(getCacheDir(), "gpu_driver_package.zip");
                downloadToFile(url, zip);
                installPackage(zip, label, url);
                runOnUiThread(() -> {
                    setMessage("Installed " + label + ". Restart the emulator before launching a game.", false);
                    refreshStatus();
                });
            } catch (Exception e) {
                runOnUiThread(() -> setMessage("Could not install GPU driver:\n" + e.getMessage(), false));
            }
        }, "GpuDriverDownload").start();
    }

    private void downloadToFile(String urlText, File target) throws Exception {
        HttpURLConnection connection = (HttpURLConnection) new URL(urlText).openConnection();
        connection.setConnectTimeout(15000);
        connection.setReadTimeout(30000);
        connection.setRequestProperty("User-Agent", "NetherSX2-Cheat-Helper");
        int code = connection.getResponseCode();
        if (code < 200 || code >= 300) {
            throw new IllegalStateException("HTTP " + code);
        }
        try (InputStream in = new BufferedInputStream(connection.getInputStream());
             FileOutputStream out = new FileOutputStream(target)) {
            byte[] buffer = new byte[65536];
            int read;
            while ((read = in.read(buffer)) != -1) {
                out.write(buffer, 0, read);
            }
        } finally {
            connection.disconnect();
        }
    }

    private void installPackage(File zip, String label, String sourceUrl) throws Exception {
        File dir = driverDir();
        deleteRecursive(dir);
        if (!dir.mkdirs() && !dir.isDirectory()) {
            throw new IllegalStateException("Could not create " + dir.getAbsolutePath());
        }

        File selected = null;
        try (ZipInputStream zin = new ZipInputStream(new FileInputStream(zip))) {
            ZipEntry entry;
            while ((entry = zin.getNextEntry()) != null) {
                String name = entry.getName();
                if (!entry.isDirectory() && name != null && name.toLowerCase(Locale.US).endsWith(".so")) {
                    boolean looksLikeVulkan = name.toLowerCase(Locale.US).contains("vulkan");
                    if (looksLikeVulkan || selected == null) {
                        File out = new File(dir, "libvulkan_freedreno.so");
                        try (FileOutputStream fout = new FileOutputStream(out)) {
                            byte[] buffer = new byte[65536];
                            int read;
                            while ((read = zin.read(buffer)) != -1) {
                                fout.write(buffer, 0, read);
                            }
                        }
                        selected = out;
                        if (looksLikeVulkan) {
                            break;
                        }
                    }
                }
            }
        }

        if (selected == null || !selected.isFile()) {
            throw new IllegalStateException("No Vulkan .so was found in the package");
        }

        String installedAt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).format(new Date());
        writeText(enabledMarker(), sourceUrl);
        writeText(new File(dir, "driver-info.txt"), label + "\n" + sourceUrl + "\n" + installedAt + "\n");
        prefs.edit()
                .putBoolean("GPUDriver/Enabled", true)
                .putString("GPUDriver/Name", label)
                .putString("GPUDriver/Url", sourceUrl)
                .putString("GPUDriver/InstalledAt", installedAt)
                .putString("EmuCore/GS/Renderer", "14")
                .apply();
    }

    private void writeText(File file, String text) throws Exception {
        try (FileOutputStream out = new FileOutputStream(file)) {
            out.write(text.getBytes("UTF-8"));
        }
    }

    private void deleteRecursive(File file) {
        if (file == null || !file.exists()) {
            return;
        }
        if (file.isDirectory()) {
            File[] children = file.listFiles();
            if (children != null) {
                for (File child : children) {
                    deleteRecursive(child);
                }
            }
        }
        file.delete();
    }
}
