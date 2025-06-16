#!/bin/bash

# Security: Log all command executions for audit trail
readonly LOGFILE="/var/log/zabbix/shell-commands.log"
readonly MAX_CMD_LENGTH=1024

# Input validation
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <command>" >&2
    exit 1
fi

COMMAND="$1"

# Validate command length
if [[ ${#COMMAND} -gt $MAX_CMD_LENGTH ]]; then
    echo "Error: Command too long (max $MAX_CMD_LENGTH characters)" >&2
    exit 1
fi

# Security: Block dangerous commands
readonly BLOCKED_COMMANDS=(
    "rm -rf /"
    "dd if="
    "mkfs"
    "fdisk"
    "parted"
    "crontab"
    "sudo"
    "su -"
    "passwd"
    "userdel"
    "usermod"
    "chmod 777"
    "chown root"
)

for blocked in "${BLOCKED_COMMANDS[@]}"; do
    if [[ "$COMMAND" =~ $blocked ]]; then
        echo "Error: Blocked command detected: $blocked" >&2
        echo "$(date): BLOCKED: $COMMAND" >> "$LOGFILE" 2>/dev/null
        exit 1
    fi
done

# Log command execution (best effort, don't fail if logging fails)
echo "$(date): EXEC: $COMMAND" >> "$LOGFILE" 2>/dev/null

# Execute with restricted environment
exec env -i PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" bash -c "$COMMAND"
