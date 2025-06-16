#!/bin/bash

# Input validation
if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <message> <host> <port>" >&2
    exit 1
fi

MESSAGE="$1"
HOST="$2"
PORT="$3"

# Validate port is numeric and in valid range
if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [[ "$PORT" -lt 1 ]] || [[ "$PORT" -gt 65535 ]]; then
    echo "Error: Port must be a number between 1 and 65535" >&2
    exit 1
fi

# Validate hostname/IP (basic check)
if [[ -z "$HOST" ]] || [[ ${#HOST} -gt 253 ]]; then
    echo "Error: Invalid hostname" >&2
    exit 1
fi

# Limit message length to prevent buffer overflow
if [[ ${#MESSAGE} -gt 4096 ]]; then
    echo "Error: Message too long (max 4096 characters)" >&2
    exit 1
fi

# Use timeout and validate nc is available
if ! command -v nc >/dev/null 2>&1; then
    echo "Error: netcat (nc) not found" >&2
    exit 1
fi

# Send with stricter timeout and error handling
echo -n "$MESSAGE" | timeout 5 nc -w1 "$HOST" "$PORT"
exit_code=$?

if [[ $exit_code -eq 124 ]]; then
    echo "Error: Connection timed out" >&2
    exit 1
elif [[ $exit_code -ne 0 ]]; then
    echo "Error: Connection failed" >&2
    exit 1
fi
