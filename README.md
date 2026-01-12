# Log Rotation Scripts

Collection of log rotation scripts for automated log file management.

## Scripts

### 1. logRotate.sh / logRotateStandalone.sh
**Standalone bash script with command-line arguments**

- No config file needed
- Takes arguments directly
- Single execution per run

**Arguments:**
1. `log_file_path` - Full path to log file
2. `rotated_logs_dir` - Directory for rotated logs

**Usage:**
```bash
./logRotate.sh <log_file_path> <rotated_logs_dir>

# Example
./logRotate.sh /var/log/app.log /var/log/rotated

# Cron example
*/30 * * * * /path/to/logRotate.sh /var/log/app.log /var/log/rotated
```

---

### 2. logRotation.sh
**Bash script for cron-based rotation (config file)**

- Single execution per run
- Reads configuration from `conf/logRotationScriptconf.json`
- Designed for cron scheduling

**Configuration:**
```json
{
  "logFilePath": "/path/to/log/file.log",
  "rotatedLogsDir": "/path/to/rotated/logs",
  "enabled": true
}
```

**Usage:**
```bash
./logRotation.sh

# Cron example (every 2 minutes)
*/2 * * * * /path/to/logRotation.sh
```

---

## How Rotation Works

1. Checks if log file exists and is not empty
2. Creates rotated logs directory if needed
3. Renames log file with timestamp: `filename-YYYY-MM-DD-HH-MM-SS.ext`
4. Moves renamed file to rotated logs directory
5. Creates new empty log file at original location

## Logs

All scripts log their activity to `rotation.log` in the script directory.
