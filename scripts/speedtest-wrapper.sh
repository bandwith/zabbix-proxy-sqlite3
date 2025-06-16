#!/bin/bash

# Security: Set secure file permissions umask
umask 077

# Display help information
function show_help {
  echo "Usage: speedtest-wrapper [OPTIONS] [-- SPEEDTEST_ARGS...]"
  echo ""
  echo "Options:"
  echo "  --ookla       Force use of Ookla Speedtest CLI"
  echo "  --cloudflare  Force use of Cloudflare Speedtest CLI"
  echo "  --help        Show this help message"
  echo ""
  echo "If no tool is specified, will try Ookla first, then Cloudflare."
}

# Security: Validate input arguments
function validate_args {
    local arg
    for arg in "$@"; do
        # Block potentially dangerous arguments
        if [[ "$arg" =~ ^-.*[;&|`$] ]]; then
            echo "Error: Potentially unsafe argument detected: $arg" >&2
            exit 1
        fi
        # Limit argument length
        if [[ ${#arg} -gt 256 ]]; then
            echo "Error: Argument too long: ${arg:0:50}..." >&2
            exit 1
        fi
    done
}

FORCE_TOOL=""
ARGS_TO_PASS=()

# Process command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --ookla)
      FORCE_TOOL="ookla"
      shift
      ;;
    --cloudflare)
      FORCE_TOOL="cloudflare"
      shift
      ;;
    --help)
      show_help
      exit 0
      ;;
    --)
      shift
      validate_args "$@"
      ARGS_TO_PASS+=("$@")
      break
      ;;
    *)
      validate_args "$1"
      ARGS_TO_PASS+=("$1")
      shift
      ;;
  esac
done

# Security: Check file permissions and ownership
function check_binary_security {
    local binary_path="$1"
    if [[ -f "$binary_path" ]]; then
        # Check if binary is writable by others (security risk)
        if [[ -w "$binary_path" ]]; then
            echo "Warning: $binary_path is writable by current user - potential security risk" >&2
        fi
        
        # Check for suspicious file size (basic integrity check)
        local file_size
        file_size=$(stat -c%s "$binary_path" 2>/dev/null || echo "0")
        if [[ "$file_size" -lt 1000 ]] || [[ "$file_size" -gt 100000000 ]]; then
            echo "Warning: $binary_path has unusual file size: $file_size bytes" >&2
        fi
    fi
}

# Check availability of speedtest tools
OOKLA_AVAILABLE="no"
if command -v speedtest &>/dev/null; then
  OOKLA_AVAILABLE="yes"
  check_binary_security "$(command -v speedtest)"
fi

CF_AVAILABLE="no"
if [ -f "/opt/venv/bin/cfspeedtest" ]; then
  CF_AVAILABLE="yes"
  check_binary_security "/opt/venv/bin/cfspeedtest"
fi

# Execute the appropriate speedtest tool with timeout
if [ "$FORCE_TOOL" = "ookla" ]; then
  if [ "$OOKLA_AVAILABLE" = "yes" ]; then
    echo "Using Ookla Speedtest CLI (forced):"
    timeout 300 speedtest "${ARGS_TO_PASS[@]}"
  else
    echo "Error: Ookla Speedtest CLI was specified but is not available"
    exit 1
  fi
elif [ "$FORCE_TOOL" = "cloudflare" ]; then
  if [ "$CF_AVAILABLE" = "yes" ]; then
    echo "Using Cloudflare Python Speedtest CLI (forced):"
    timeout 300 /opt/venv/bin/cfspeedtest "${ARGS_TO_PASS[@]}"
  else
    echo "Error: Cloudflare Speedtest CLI was specified but is not available"
    exit 1
  fi
else
  # Auto-select based on availability (preferring Ookla)
  if [ "$OOKLA_AVAILABLE" = "yes" ]; then
    echo "Using Ookla Speedtest CLI:"
    timeout 300 speedtest "${ARGS_TO_PASS[@]}"
  elif [ "$CF_AVAILABLE" = "yes" ]; then
    echo "Using Cloudflare Python Speedtest CLI:"
    timeout 300 /opt/venv/bin/cfspeedtest "${ARGS_TO_PASS[@]}"
  else
    echo "Error: No speedtest implementation found"
    exit 1
  fi
fi
