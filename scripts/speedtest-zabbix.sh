#!/bin/bash
# Speedtest script that runs both Ookla and Cloudflare speedtests
# and provides more user-friendly output

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print header
echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}      Network Speed Test Results              ${NC}"
echo -e "${BLUE}===============================================${NC}"
echo ""

# Function to test if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Define test functions
run_ookla_speedtest() {
  echo -e "${YELLOW}Running Ookla Speedtest...${NC}"
  if speedtest --accept-license --accept-gdpr -p no; then
    return 0
  else
    return 1
  fi
}

run_cloudflare_speedtest() {
  echo -e "${YELLOW}Running Cloudflare Speedtest...${NC}"
  if cfspeedtest -json=false; then
    return 0
  else
    return 1
  fi
}

# Variable to track if any test succeeded
any_success=false

# Try Ookla Speedtest
if command_exists speedtest; then
  echo -e "${BLUE}[1] Ookla Speedtest CLI${NC}"
  if run_ookla_speedtest; then
    echo -e "${GREEN}✓ Ookla Speedtest completed successfully${NC}"
    any_success=true
  else
    echo -e "${RED}✗ Ookla Speedtest failed${NC}"
  fi
  echo ""
else
  echo -e "${RED}Ookla Speedtest CLI not installed${NC}"
  echo ""
fi

# Try Cloudflare Speedtest
if command_exists cfspeedtest; then
  echo -e "${BLUE}[2] Cloudflare Speedtest${NC}"
  if run_cloudflare_speedtest; then
    echo -e "${GREEN}✓ Cloudflare Speedtest completed successfully${NC}"
    any_success=true
  else
    echo -e "${RED}✗ Cloudflare Speedtest failed${NC}"
  fi
  echo ""
else
  echo -e "${RED}Cloudflare Speedtest not installed${NC}"
  echo ""
fi

# Show final status
if [ "$any_success" = true ]; then
  echo -e "${GREEN}At least one speed test completed successfully.${NC}"
  exit 0
else
  echo -e "${RED}All speed test implementations failed.${NC}"
  exit 1
fi
