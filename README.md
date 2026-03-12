# UnplugMe 🔋

UnplugMe is a lightweight, zero-dependency macOS background service that monitors your laptop's battery and notifies you when it reaches your target charge level (default 80%). It helps preserve your MacBook's battery lifespan by preventing prolonged 100% charging states.

It runs silently in the background using macOS's native `launchd` and uses zero third-party wrappers, meaning it consumes effectively **0% CPU**.

## ✨ Features
- **Silent Background Nudges:** Automatically checks your battery every 2 minutes. If plugged in and $\geq$ 80%, it sends a sliding macOS system notification to nudge you to unplug.
- **Adjustable Target:** You can natively configure your target stopping point (e.g. 80%, 85%, 90%) using a simple config file.
- **Battery Health Logging (Optional):** Flip a switch in the config file to quietly generate a `health_log.csv` file mapping out your Cycle Counts, Max Capacity, and degradation over time. 

## 🚀 Installation

Open the **Terminal** app on your Mac and paste the following command:

```bash
curl -sL https://raw.githubusercontent.com/tubolyroli/unplugme/main/install.sh | bash
```

## ⚙️ Configuration
After installing, your active service files are located safely inside a hidden folder in your home directory (`~/.unplugme`). 

To change your settings, open the `config.txt` file by running this in your terminal:
```bash
open ~/.unplugme/config.txt
```

Inside, you will see two variables:
- `TARGET_PCT=80` *(Change this to any percentage you want the notification to trigger at)*
- `ENABLE_HEALTH_LOG=false` *(Change this to `true` if you want UnplugMe to automatically document your long-term battery cycle health in a CSV file!)*

## 🛑 Uninstallation
Don't want it anymore? You can instantly remove UnplugMe, its background daemon, and its config files by running the included uninstaller:

```bash
curl -sL https://raw.githubusercontent.com/tubolyroli/unplugme/main/uninstall.sh | bash
```
