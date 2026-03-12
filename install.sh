#!/bin/bash

# Web Installer for UnplugMe (GitHub Version)

REPO_URL="https://raw.githubusercontent.com/tubolyroli/unplugme/main"

echo "Downloading and Installing UnplugMe from GitHub..."

# Define paths
INSTALL_DIR="$HOME/.unplugme"
PLIST_NAME="com.user.unplugme.plist"
LAUNCH_DIR="$HOME/Library/LaunchAgents"

# Create directories
mkdir -p "$INSTALL_DIR" || { echo "Error: Failed to create $INSTALL_DIR"; exit 1; }
mkdir -p "$LAUNCH_DIR" || { echo "Error: Failed to create $LAUNCH_DIR"; exit 1; }

# Download the core scripts directly from GitHub
echo "Fetching latest core script..."
curl -fsSL "$REPO_URL/unplugme.sh" -o "$INSTALL_DIR/unplugme.sh" || { echo "Error: Failed to download unplugme.sh"; exit 1; }
curl -fsSL "$REPO_URL/uninstall.sh" -o "$INSTALL_DIR/uninstall.sh" || { echo "Error: Failed to download uninstall.sh"; exit 1; }
chmod +x "$INSTALL_DIR/unplugme.sh" "$INSTALL_DIR/uninstall.sh" || { echo "Error: Failed to set executable permissions"; exit 1; }

# Create log file & Default config
touch "$INSTALL_DIR/unplugme.log" || { echo "Error: Failed to create log file"; exit 1; }
if [ ! -f "$INSTALL_DIR/config.txt" ]; then
    echo "TARGET_PCT=80" > "$INSTALL_DIR/config.txt"
    echo "ENABLE_HEALTH_LOG=false" >> "$INSTALL_DIR/config.txt"
    echo "MAX_LOG_SIZE_MB=1024" >> "$INSTALL_DIR/config.txt"
    echo "# You can change the target percentage above. Example: TARGET_PCT=85" >> "$INSTALL_DIR/config.txt"
    echo "# MAX_LOG_SIZE_MB: Maximum size in MB before the log file is cleared. Default is 1024 (1GB)." >> "$INSTALL_DIR/config.txt"
fi

# Download and explicitly configure the plist
echo "Configuring background service..."
curl -fsSL "$REPO_URL/com.user.unplugme.plist.template" -o "/tmp/unplugme.plist.template" || { echo "Error: Failed to download plist template"; exit 1; }
sed "s|REPLACE_WITH_PATH|$INSTALL_DIR|g; s|REPLACE_WITH_HOME|$HOME|g" "/tmp/unplugme.plist.template" > "$LAUNCH_DIR/$PLIST_NAME" || { echo "Error: Failed to configure plist"; exit 1; }
rm "/tmp/unplugme.plist.template"

# Load the service
echo "Loading launchd service..."
launchctl unload "$LAUNCH_DIR/$PLIST_NAME" 2>/dev/null
launchctl load "$LAUNCH_DIR/$PLIST_NAME" || { echo "Error: Failed to load launchd service"; exit 1; }

echo "----------------------------------------"
echo "UnplugMe installed successfully!"
echo "It will now check your battery every 2 minutes in the background."
echo "If you want to track your Battery Health CSV, edit ~/.unplugme/config.txt and set ENABLE_HEALTH_LOG=true"
echo "Logs are available at $INSTALL_DIR/unplugme.log"
