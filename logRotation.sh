#!/bin/bash

# Log Rotation Script
# Run this via cron for automatic log rotation

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/conf/logRotationScriptconf.json"
ROTATION_LOG="$SCRIPT_DIR/rotation.log"

# Function to log messages
log_msg() {
    local timestamp=$(date '+%Y-%m-%dT%H:%M:%S')
    local message="[$timestamp] $1"
    echo "$message"
    echo "$message" >> "$ROTATION_LOG"
}

# Function to read JSON config (using grep and sed for simplicity)
get_config_value() {
    local key="$1"
    # Handle both quoted strings and unquoted values (booleans, numbers)
    grep "\"$key\"" "$CONFIG_FILE" | sed 's/.*: *"\?\([^",}]*\)"\?.*/\1/' | tr -d ' ,'
}

# Load configuration
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found: $CONFIG_FILE"
    exit 1
fi

LOG_FILE_PATH=$(get_config_value "logFilePath")
ROTATED_LOGS_DIR=$(get_config_value "rotatedLogsDir")
ENABLED=$(get_config_value "enabled")

# Check if rotation is enabled
if [ "$ENABLED" != "true" ]; then
    log_msg "⏸️  Log rotation is disabled in config"
    exit 0
fi

# Function to generate timestamp
get_timestamp() {
    date '+%Y-%m-%d-%H-%M-%S'
}

# Main rotation function
rotate_log() {
    log_msg "========================================"
    log_msg "🔄 Starting log rotation"
    log_msg "========================================"

    log_msg "📂 Log file: $LOG_FILE_PATH"

    # Check if log file exists
    if [ ! -f "$LOG_FILE_PATH" ]; then
        log_msg "❌ Log file does not exist: $LOG_FILE_PATH"
        return 1
    fi

    # Get file size
    FILE_SIZE=$(stat -f%z "$LOG_FILE_PATH" 2>/dev/null || stat -c%s "$LOG_FILE_PATH" 2>/dev/null)
    FILE_SIZE_MB=$(echo "scale=2; $FILE_SIZE/1024/1024" | bc)

    log_msg "📊 Log file size: ${FILE_SIZE_MB} MB"

    # Check if file is empty
    if [ "$FILE_SIZE" -eq 0 ]; then
        log_msg "❌ Log file is empty, skipping rotation"
        return 1
    fi

    # Create rotated logs directory if it doesn't exist
    if [ ! -d "$ROTATED_LOGS_DIR" ]; then
        log_msg "📁 Creating directory: $ROTATED_LOGS_DIR"
        mkdir -p "$ROTATED_LOGS_DIR"
    fi

    # Generate new filename with timestamp
    TIMESTAMP=$(get_timestamp)
    FILENAME=$(basename "$LOG_FILE_PATH")
    EXTENSION="${FILENAME##*.}"
    BASENAME="${FILENAME%.*}"
    NEW_FILENAME="${BASENAME}-${TIMESTAMP}.${EXTENSION}"
    NEW_FILE_PATH="$ROTATED_LOGS_DIR/$NEW_FILENAME"

    log_msg "🔄 Rotating: $FILENAME → $NEW_FILENAME"

    # Move the log file to rotated directory
    if mv "$LOG_FILE_PATH" "$NEW_FILE_PATH"; then
        log_msg "✅ File moved to: $NEW_FILE_PATH"
    else
        log_msg "❌ Failed to move file"
        return 1
    fi

    # Create new empty log file
    if touch "$LOG_FILE_PATH"; then
        log_msg "✅ New empty file created: $LOG_FILE_PATH"
    else
        log_msg "❌ Failed to create new empty file"
        return 1
    fi

    log_msg "✅ SUCCESS! Rotated ${FILE_SIZE_MB} MB"
    log_msg "========================================"

    return 0
}

# Execute rotation
rotate_log

exit $?
