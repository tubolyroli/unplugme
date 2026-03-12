# UnplugMe 🔋

> A lightweight, zero-dependency macOS background service that nudges you to unplug your charger when your battery reaches a target level — helping preserve your MacBook's long-term battery health.

UnplugMe monitors your battery and sends a native macOS notification when it's plugged in and reaches your target charge level (default 80%). It helps prevent prolonged 100% charging states, which degrade lithium-ion battery lifespan over time.

It runs silently in the background using macOS's native `launchd` and uses zero third-party wrappers, meaning it consumes effectively **0% CPU**.

## 📋 Requirements

- **macOS** (tested on Ventura 13+, Sonoma 14+, Sequoia 15+)
- A MacBook with a built-in battery
- No dependencies, no Homebrew, no Python — just native macOS tools (`bash`, `launchd`, `pmset`, `osascript`)

## ✨ Features
- **Silent Background Nudges:** Automatically checks your battery every 2 minutes. If plugged in and $\geq$ 80%, it sends a sliding macOS system notification to nudge you to unplug.
- **Adjustable Target:** You can natively configure your target stopping point (e.g. 80%, 85%, 90%) using a simple config file.
- **Battery Health Logging (Optional):** Flip a switch in the config file to quietly generate a `health_log.csv` file mapping out your Cycle Counts, Max Capacity, and degradation over time. 

## � How It Works

UnplugMe registers a lightweight `launchd` agent (macOS's native task scheduler) that runs a small shell script every **2 minutes**. Each run:

1. Reads your battery state via `pmset -g batt`
2. Checks if you're on AC power **and** at or above your target percentage
3. If both are true, sends a native macOS notification via `osascript`
4. Optionally logs battery health data (cycle count, max capacity, condition) via `system_profiler`

No daemons, no background apps, no menu bar icons — just a single scheduled script.

## �🚀 Installation

Open the **Terminal** app on your Mac and paste the following command:

```bash
curl -sL https://raw.githubusercontent.com/tubolyroli/unplugme/main/install.sh | bash
```

### ✅ Verify it's running

After installing, confirm the service is loaded:

```bash
launchctl list | grep unplugme
```

You should see a line containing `com.user.unplugme`. If you don't, try logging out and back in, or run:

```bash
launchctl load ~/Library/LaunchAgents/com.user.unplugme.plist
```

## 📂 What gets installed

All files live in `~/.unplugme/` and a single plist in `~/Library/LaunchAgents/`:

| File | Purpose |
|------|---------|
| `~/.unplugme/unplugme.sh` | Core script that checks battery and sends notifications |
| `~/.unplugme/config.txt` | Your configuration (target %, health logging toggle) |
| `~/.unplugme/unplugme.log` | Activity log (check runs, notifications sent) |
| `~/.unplugme/error.log` | Standard error output from the script |
| `~/.unplugme/out.log` | Standard output from the script |
| `~/.unplugme/health_log.csv` | *(Only if enabled)* Battery health history |
| `~/Library/LaunchAgents/com.user.unplugme.plist` | The `launchd` agent that schedules the script |

## ⚙️ Configuration
After installing, your active service files are located safely inside a hidden folder in your home directory (`~/.unplugme`). 

To change your settings, open the `config.txt` file by running this in your terminal:
```bash
open ~/.unplugme/config.txt
```

Inside, you will see two variables:
- `TARGET_PCT=80` *(Change this to any percentage you want the notification to trigger at)*
- `ENABLE_HEALTH_LOG=false` *(Change this to `true` if you want UnplugMe to automatically document your long-term battery cycle health in a CSV file!)*

> **Note:** Changes to `config.txt` take effect automatically on the next check cycle (within 2 minutes). No restart needed.

### 📊 Battery Health Log

When `ENABLE_HEALTH_LOG=true`, UnplugMe appends a row to `~/.unplugme/health_log.csv` every 2 minutes with:

| Column | Description |
|--------|-------------|
| `Date` | Date of the reading |
| `Time` | Time of the reading |
| `BatteryPct` | Current battery percentage |
| `ChargingState` | `Charging/AC` or `Discharging/Battery` |
| `CycleCount` | Total charge cycles on the battery |
| `MaxCapacity` | Current maximum capacity (e.g. `95%`) |
| `Condition` | Battery condition reported by macOS (e.g. `Normal`) |

You can open it in any spreadsheet app or analyze trends over time.

## ⚠️ Troubleshooting

### Notifications not appearing?

If UnplugMe is running but you're not seeing any notifications, the most common cause is **macOS Focus modes** (e.g. Do Not Disturb, Work, Sleep, etc.). Focus modes suppress notifications system-wide, which prevents UnplugMe's alerts from appearing.

**To fix this:**
1. Open **System Settings → Focus**.
2. Select the Focus mode you have active (e.g. *Do Not Disturb*).
3. Under **Allowed Notifications**, click **Apps** and add **Script Editor** (since UnplugMe uses `osascript` to send notifications).
4. Alternatively, you can temporarily disable the active Focus mode from Control Center.

### Other things to check
- Make sure the service is actually running: `launchctl list | grep unplugme`
- Check the log file for errors: `cat ~/.unplugme/unplugme.log`
- Check the error log: `cat ~/.unplugme/error.log`
- Verify your config file is valid: `cat ~/.unplugme/config.txt`
- If the service won't load, try unloading first: `launchctl unload ~/Library/LaunchAgents/com.user.unplugme.plist` then load again
- As a last resort, re-run the install command — it will overwrite the scripts and reload the service cleanly

### Log file growing too large?

The log file (`~/.unplugme/unplugme.log`) will grow over time since a line is written every 2 minutes. To clear it:

```bash
> ~/.unplugme/unplugme.log
```

## 🛑 Uninstallation
Don't want it anymore? You can instantly remove UnplugMe, its background daemon, and its config files by running the included uninstaller:

```bash
curl -sL https://raw.githubusercontent.com/tubolyroli/unplugme/main/uninstall.sh | bash
```

This removes the `launchd` agent, the `~/.unplugme/` directory, and all associated files (including logs and the health CSV).

---

Made by [tubolyroli](https://github.com/tubolyroli). If something's broken, let me know 🙂