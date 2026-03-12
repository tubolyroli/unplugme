#!/bin/bash

# UnplugMe Core Script
# Checks if the battery is charging and >= TARGET_PCT. If so, sends a notification.

# Determine paths
LOG_FILE="$HOME/.unplugme/unplugme.log"
CONFIG_FILE="$HOME/.unplugme/config.txt"
HEALTH_LOG="$HOME/.unplugme/health_log.csv"

# Ensure config exists
if [ ! -f "$CONFIG_FILE" ]; then
    mkdir -p "$(dirname "$CONFIG_FILE")"
    echo "TARGET_PCT=80" > "$CONFIG_FILE"
    echo "ENABLE_HEALTH_LOG=false" >> "$CONFIG_FILE"
    echo "MAX_LOG_SIZE_MB=1024" >> "$CONFIG_FILE"
    echo "# You can change the target percentage above. Example: TARGET_PCT=85" >> "$CONFIG_FILE"
    echo "# MAX_LOG_SIZE_MB: Maximum size in MB before the log file is cleared. Default is 1024 (1GB)." >> "$CONFIG_FILE"
fi

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to check and clear log size
check_log_size() {
    local file=$1
    if [ -f "$file" ]; then
        local size=$(stat -f%z "$file" 2>/dev/null || echo 0)
        if [ "$size" -gt "$MAX_LOG_SIZE_BYTES" ]; then
            > "$file"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Log file $(basename "$file") exceeded ${MAX_LOG_SIZE_MB}MB. Cleared." >> "$LOG_FILE"
        fi
    fi
}

# Load config
source "$CONFIG_FILE"

# Validate TARGET_PCT (must be an integer between 1 and 100)
if ! [[ "$TARGET_PCT" =~ ^[0-9]+$ ]] || [ "$TARGET_PCT" -lt 1 ] || [ "$TARGET_PCT" -gt 100 ]; then
    log "Error: Invalid TARGET_PCT in config.txt ('$TARGET_PCT'). Using default of 80."
    TARGET_PCT=80
fi

# Validate MAX_LOG_SIZE_MB (must be a positive integer)
if ! [[ "$MAX_LOG_SIZE_MB" =~ ^[0-9]+$ ]] || [ "$MAX_LOG_SIZE_MB" -lt 1 ]; then
    log "Error: Invalid MAX_LOG_SIZE_MB in config.txt ('$MAX_LOG_SIZE_MB'). Using default of 1024."
    MAX_LOG_SIZE_MB=1024
fi

MAX_LOG_SIZE_BYTES=$((MAX_LOG_SIZE_MB * 1024 * 1024))

# Run log size checks (Main log only)
check_log_size "$LOG_FILE"

# The pmset command output looks like this:
# Now drawing from 'AC Power'
# -InternalBattery-0 (id=123)	100%; charged; 0:00 remaining present: true

# Check if pmset override is set (for testing purposes)
if [ -n "$PMSET_OVERRIDE_OUTPUT" ]; then
    PMSET_OUT="$PMSET_OVERRIDE_OUTPUT"
    log "Using overridden pmset output for testing."
else
    PMSET_OUT=$(pmset -g batt)
fi

# Extract the percentage numbers only
BATTERY_PCT=$(echo "$PMSET_OUT" | grep -oEo '[0-9]+%' | grep -oEo '[0-9]+' | head -1)

# Ensure BATTERY_PCT is not empty
if [ -z "$BATTERY_PCT" ]; then
    log "Error: Could not determine battery percentage."
    exit 1
fi

# We need the charging state string from pmset for the log
if echo "$PMSET_OUT" | grep -iq "AC Power"; then
    CHARGING_STATE="Charging/AC"
    IS_CHARGING=true
else
    CHARGING_STATE="Discharging/Battery"
    IS_CHARGING=false
fi

# ==========================
# Feature 1: Battery Health Logging (Toggled via Config)
# ==========================
if [ "$ENABLE_HEALTH_LOG" = "true" ]; then
    if [ ! -f "$HEALTH_LOG" ]; then
        # Create header if file doesn't exist
        echo "Date,Time,BatteryPct,ChargingState,CycleCount,MaxCapacity,Condition" > "$HEALTH_LOG"
    fi

    # Parse system_profiler for battery health stats
    SYS_PROFILER=$(system_profiler SPPowerDataType 2>/dev/null)
    CYCLE_COUNT=$(echo "$SYS_PROFILER" | awk -F': ' '/Cycle Count/ {print $2}')
    MAX_CAPACITY=$(echo "$SYS_PROFILER" | awk -F': ' '/Maximum Capacity/ {print $2}')
    CONDITION=$(echo "$SYS_PROFILER" | awk -F': ' '/Condition/ {print $2}')

    # Append to CSV
    DATE_STR=$(date '+%Y-%m-%d')
    TIME_STR=$(date '+%H:%M:%S')
    echo "$DATE_STR,$TIME_STR,$BATTERY_PCT,$CHARGING_STATE,$CYCLE_COUNT,$MAX_CAPACITY,$CONDITION" >> "$HEALTH_LOG"
fi
# ==========================

# We only care if we are connected to power AND battery is dropping down to the target or above.
if [ "$IS_CHARGING" = true ]; then
    if [ "$BATTERY_PCT" -ge "$TARGET_PCT" ]; then
        # Check if the battery status explicitly says "discharging" despite AC Power (rare)
        if echo "$PMSET_OUT" | grep -iq "discharging"; then
            log "Battery is >= ${TARGET_PCT}% ($BATTERY_PCT%), but state is 'discharging'. Ignoring."
            exit 0
        fi

        log "Battery is at ${BATTERY_PCT}% and plugged in. Sending notification."
        osascript -e "display notification \"Your battery has reached ${BATTERY_PCT}%. Please unplug your charger to preserve battery lifespan.\" with title \"UnplugMe\" sound name \"Glass\""
    else
        log "Battery is charging but below target ${TARGET_PCT}% ($BATTERY_PCT%). Doing nothing."
    fi
else
    log "Battery is currently discharging (on battery power, $BATTERY_PCT%). Doing nothing."
fi
