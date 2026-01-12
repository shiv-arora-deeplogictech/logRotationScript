#!/bin/bash

# Standalone Log Rotation Script
# Usage: ./logRotate.sh <log_file_path> <rotated_logs_dir>

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROTATION_LOG="$SCRIPT_DIR/rotation.log"

# Function to log messages
log_msg() {
    local timestamp=$(date '+%Y-%m-%dT%H:%M:%S')
    local message="[$timestamp] $1"
    echo "$message"
    echo "$message" >> "$ROTATION_LOG"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 <log_file_path> <rotated_logs_dir>

Arguments:
  log_file_path      - Full path to the log file to rotate
  rotated_logs_dir   - Directory where rotated logs will be stored

Example:
  $0 /var/log/app.log /var/log/rotated

Description:
  This script rotates a log file by:
  1. Moving the current log file to the rotated logs directory with a timestamp
  2. Creating a new empty log file at the original location

EOF
    exit 1
}

# Check if correct number of arguments provided
if [ "$#" -ne 2 ]; then
    echo "ERROR: Incorrect number of arguments"
    echo ""
    show_usage
fi

# Get arguments
LOG_FILE_PATH="$1"
ROTATED_LOGS_DIR="$2"

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
    log_msg "📂 Rotated dir: $ROTATED_LOGS_DIR"

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
        if [ $? -ne 0 ]; then
            log_msg "❌ Failed to create directory: $ROTATED_LOGS_DIR"
            return 1
        fi
    fi

    # Generate new filename with timestamp
    TIMESTAMP=$(get_timestamp)
    FILENAME=$(basename "$LOG_FILE_PATH")
    EXTENSION="${FILENAME##*.}"
    BASENAME="${FILENAME%.*}"

    # Handle files without extension
    if [ "$EXTENSION" = "$FILENAME" ]; then
        NEW_FILENAME="${FILENAME}-${TIMESTAMP}"
    else
        NEW_FILENAME="${BASENAME}-${TIMESTAMP}.${EXTENSION}"
    fi

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
