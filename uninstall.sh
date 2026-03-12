#!/bin/bash

# Uninstaller for UnplugMe

echo "Uninstalling UnplugMe..."

# Define paths
INSTALL_DIR="$HOME/.unplugme"
PLIST_NAME="com.user.unplugme.plist"
LAUNCH_DIR="$HOME/Library/LaunchAgents"

echo "Unloading launchd service..."
launchctl unload "$LAUNCH_DIR/$PLIST_NAME" 2>/dev/null

echo "Removing plist file..."
rm -f "$LAUNCH_DIR/$PLIST_NAME"

echo "Removing script and logs..."
rm -rf "$INSTALL_DIR"

echo "----------------------------------------"
echo "UnplugMe uninstalled completely."
