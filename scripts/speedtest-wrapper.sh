#!/bin/bash

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
      ARGS_TO_PASS+=("$@")
      break
      ;;
    *)
      ARGS_TO_PASS+=("$1")
      shift
      ;;
  esac
done

# Check availability of speedtest tools
OOKLA_AVAILABLE="no"
if command -v speedtest &>/dev/null; then
  OOKLA_AVAILABLE="yes"
fi

CF_AVAILABLE="no"
if [ -f "/opt/venv/bin/cfspeedtest" ]; then
  CF_AVAILABLE="yes"
fi

# Execute the appropriate speedtest tool
if [ "$FORCE_TOOL" = "ookla" ]; then
  if [ "$OOKLA_AVAILABLE" = "yes" ]; then
    echo "Using Ookla Speedtest CLI (forced):"
    speedtest "${ARGS_TO_PASS[@]}"
  else
    echo "Error: Ookla Speedtest CLI was specified but is not available"
    exit 1
  fi
elif [ "$FORCE_TOOL" = "cloudflare" ]; then
  if [ "$CF_AVAILABLE" = "yes" ]; then
    echo "Using Cloudflare Python Speedtest CLI (forced):"
    /opt/venv/bin/cfspeedtest "${ARGS_TO_PASS[@]}"
  else
    echo "Error: Cloudflare Speedtest CLI was specified but is not available"
    exit 1
  fi
else
  # Auto-select based on availability (preferring Ookla)
  if [ "$OOKLA_AVAILABLE" = "yes" ]; then
    echo "Using Ookla Speedtest CLI:"
    speedtest "${ARGS_TO_PASS[@]}"
  elif [ "$CF_AVAILABLE" = "yes" ]; then
    echo "Using Cloudflare Python Speedtest CLI:"
    /opt/venv/bin/cfspeedtest "${ARGS_TO_PASS[@]}"
  else
    echo "Error: No speedtest implementation found"
    exit 1
  fi
fi
