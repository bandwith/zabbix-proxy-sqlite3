# Base Zabbix proxy image with SQLite3
# Global hadolint ignore directives
# hadolint global ignore=DL3003,DL3008,DL4001,DL3047,SC2015,SC2016
ARG ZABBIX_VERSION=ubuntu-7.2.7
FROM zabbix/zabbix-proxy-sqlite3:${ZABBIX_VERSION}

# Switch to root for installation tasks
USER root

# Use bash with improved error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set environment variables for better security
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    MIBS=+ALL

# Create directory for custom SNMP MIBs
RUN mkdir -p /usr/share/snmp/mibs/custom && \
    chown -R 1997:1997 /usr/share/snmp/mibs/custom && \
    chmod 755 /usr/share/snmp/mibs/custom

# Install system utilities and monitoring tools
# - Network diagnostics: ping, traceroute, nmap, etc.
# - Management tools: curl, wget, nano
# - Monitoring: snmp, fping
# - Data processing: jq, jo
# Note: We don't pin versions to ensure we get security updates
# hadolint ignore=DL3008,DL4001,DL3047
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Network diagnostic tools
    iputils-ping \
    iputils-tracepath \
    traceroute \
    fping \
    dnsutils \
    nmap \
    netcat-openbsd \
    mtr \
    iproute2 \
    tcpdump \
    # SNMP monitoring
    snmp \
    snmp-mibs-downloader \
    # Download and system tools
    curl \
    wget \
    ca-certificates \
    nano \
    # JSON processing
    jq \
    jo \
    # Scripting support
    expect \
    # Python support
    python3 \
    python3-pip \
    python3-setuptools \
    # Package management
    gnupg \
    # Security tools
    apt-transport-https \
    # Clean up to reduce image size
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Speedtest tools - both Cloudflare and Ookla (with fallbacks)
# hadolint ignore=DL3008,DL3003

# Install necessary dependencies
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gnupg ca-certificates apt-transport-https curl dirmngr nodejs npm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create wrapper script for speedtest implementations
# Using single quotes is fine for shell code without variables
# hadolint ignore=SC2016
RUN echo '#!/bin/bash' > /usr/local/bin/speedtest-wrapper && \
    echo '' >> /usr/local/bin/speedtest-wrapper && \
    echo '# Display help information' >> /usr/local/bin/speedtest-wrapper && \
    echo 'function show_help {' >> /usr/local/bin/speedtest-wrapper && \
    echo '  echo "Usage: speedtest-wrapper [OPTIONS] [-- SPEEDTEST_ARGS...]"' >> /usr/local/bin/speedtest-wrapper && \
    echo '  echo ""' >> /usr/local/bin/speedtest-wrapper && \
    echo '  echo "Options:"' >> /usr/local/bin/speedtest-wrapper && \
    echo '  echo "  --ookla       Force use of Ookla Speedtest CLI"' >> /usr/local/bin/speedtest-wrapper && \
    echo '  echo "  --cloudflare  Force use of Cloudflare Speedtest CLI"' >> /usr/local/bin/speedtest-wrapper && \
    echo '  echo "  --help        Show this help message"' >> /usr/local/bin/speedtest-wrapper && \
    echo '  echo ""' >> /usr/local/bin/speedtest-wrapper && \
    echo '  echo "If no tool is specified, will try Ookla first, then Cloudflare."' >> /usr/local/bin/speedtest-wrapper && \
    echo '}' >> /usr/local/bin/speedtest-wrapper && \
    echo '' >> /usr/local/bin/speedtest-wrapper && \
    echo 'FORCE_TOOL=""' >> /usr/local/bin/speedtest-wrapper && \
    echo 'ARGS_TO_PASS=()' >> /usr/local/bin/speedtest-wrapper && \
    echo '' >> /usr/local/bin/speedtest-wrapper && \
    echo '# Process command line arguments' >> /usr/local/bin/speedtest-wrapper && \
    echo 'while [[ $# -gt 0 ]]; do' >> /usr/local/bin/speedtest-wrapper && \
    echo '  case $1 in' >> /usr/local/bin/speedtest-wrapper && \
    echo '    --ookla)' >> /usr/local/bin/speedtest-wrapper && \
    echo '      FORCE_TOOL="ookla"' >> /usr/local/bin/speedtest-wrapper && \
    echo '      shift' >> /usr/local/bin/speedtest-wrapper && \
    echo '      ;;' >> /usr/local/bin/speedtest-wrapper && \
    echo '    --cloudflare)' >> /usr/local/bin/speedtest-wrapper && \
    echo '      FORCE_TOOL="cloudflare"' >> /usr/local/bin/speedtest-wrapper && \
    echo '      shift' >> /usr/local/bin/speedtest-wrapper && \
    echo '      ;;' >> /usr/local/bin/speedtest-wrapper && \
    echo '    --help)' >> /usr/local/bin/speedtest-wrapper && \
    echo '      show_help' >> /usr/local/bin/speedtest-wrapper && \
    echo '      exit 0' >> /usr/local/bin/speedtest-wrapper && \
    echo '      ;;' >> /usr/local/bin/speedtest-wrapper && \
    echo '    --)' >> /usr/local/bin/speedtest-wrapper && \
    echo '      shift' >> /usr/local/bin/speedtest-wrapper && \
    echo '      # Add remaining arguments to pass through' >> /usr/local/bin/speedtest-wrapper && \
    echo '      ARGS_TO_PASS+=("$@")' >> /usr/local/bin/speedtest-wrapper && \
    echo '      break' >> /usr/local/bin/speedtest-wrapper && \
    echo '      ;;' >> /usr/local/bin/speedtest-wrapper && \
    echo '    *)' >> /usr/local/bin/speedtest-wrapper && \
    echo '      ARGS_TO_PASS+=("$1")' >> /usr/local/bin/speedtest-wrapper && \
    echo '      shift' >> /usr/local/bin/speedtest-wrapper && \
    echo '      ;;' >> /usr/local/bin/speedtest-wrapper && \
    echo '  esac' >> /usr/local/bin/speedtest-wrapper && \
    echo 'done' >> /usr/local/bin/speedtest-wrapper && \
    echo '' >> /usr/local/bin/speedtest-wrapper && \
    echo '# Determine which tool to use based on availability and user preference' >> /usr/local/bin/speedtest-wrapper && \
    echo 'OOKLA_AVAILABLE=$(command -v speedtest >/dev/null 2>&1 && echo "yes" || echo "no")' >> /usr/local/bin/speedtest-wrapper && \
    echo 'CF_AVAILABLE=$([ -f "/opt/venv/bin/cfspeedtest" ] && echo "yes" || echo "no")' >> /usr/local/bin/speedtest-wrapper && \
    echo '' >> /usr/local/bin/speedtest-wrapper && \
    echo '# Handle forced tool selection' >> /usr/local/bin/speedtest-wrapper && \
    echo 'if [ "$FORCE_TOOL" = "ookla" ]; then' >> /usr/local/bin/speedtest-wrapper && \
    echo '  if [ "$OOKLA_AVAILABLE" = "yes" ]; then' >> /usr/local/bin/speedtest-wrapper && \
    echo '    echo "Using Ookla Speedtest CLI (forced):"' >> /usr/local/bin/speedtest-wrapper && \
    echo '    speedtest "${ARGS_TO_PASS[@]}"' >> /usr/local/bin/speedtest-wrapper && \
    echo '  else' >> /usr/local/bin/speedtest-wrapper && \
    echo '    echo "Error: Ookla Speedtest CLI was specified but is not available"' >> /usr/local/bin/speedtest-wrapper && \
    echo '    exit 1' >> /usr/local/bin/speedtest-wrapper && \
    echo '  fi' >> /usr/local/bin/speedtest-wrapper && \
    echo 'elif [ "$FORCE_TOOL" = "cloudflare" ]; then' >> /usr/local/bin/speedtest-wrapper && \
    echo '  if [ "$CF_AVAILABLE" = "yes" ]; then' >> /usr/local/bin/speedtest-wrapper && \
    echo '    echo "Using Cloudflare Python Speedtest CLI (forced):"' >> /usr/local/bin/speedtest-wrapper && \
    echo '    /opt/venv/bin/cfspeedtest "${ARGS_TO_PASS[@]}"' >> /usr/local/bin/speedtest-wrapper && \
    echo '  else' >> /usr/local/bin/speedtest-wrapper && \
    echo '    echo "Error: Cloudflare Speedtest CLI was specified but is not available"' >> /usr/local/bin/speedtest-wrapper && \
    echo '    exit 1' >> /usr/local/bin/speedtest-wrapper && \
    echo '  fi' >> /usr/local/bin/speedtest-wrapper && \
    echo 'else' >> /usr/local/bin/speedtest-wrapper && \
    echo '  # Auto-select based on availability (preferring Ookla)' >> /usr/local/bin/speedtest-wrapper && \
    echo '  if [ "$OOKLA_AVAILABLE" = "yes" ]; then' >> /usr/local/bin/speedtest-wrapper && \
    echo '    echo "Using Ookla Speedtest CLI:"' >> /usr/local/bin/speedtest-wrapper && \
    echo '    speedtest "${ARGS_TO_PASS[@]}"' >> /usr/local/bin/speedtest-wrapper && \
    echo '  elif [ "$CF_AVAILABLE" = "yes" ]; then' >> /usr/local/bin/speedtest-wrapper && \
    echo '    echo "Using Cloudflare Python Speedtest CLI:"' >> /usr/local/bin/speedtest-wrapper && \
    echo '    /opt/venv/bin/cfspeedtest "${ARGS_TO_PASS[@]}"' >> /usr/local/bin/speedtest-wrapper && \
    echo '  else' >> /usr/local/bin/speedtest-wrapper && \
    echo '    echo "Error: No speedtest implementation found"' >> /usr/local/bin/speedtest-wrapper && \
    echo '    exit 1' >> /usr/local/bin/speedtest-wrapper && \
    echo '  fi' >> /usr/local/bin/speedtest-wrapper && \
    echo 'fi' >> /usr/local/bin/speedtest-wrapper

# Make wrapper executable and create symlink
RUN chmod +x /usr/local/bin/speedtest-wrapper && \
    mv /usr/local/bin/speedtest-wrapper /usr/local/bin/speedtest-any

# Install Cloudflare Speedtest Python CLI (cloudflarepycli)
# hadolint ignore=DL3008
WORKDIR /tmp
RUN echo "Installing Cloudflare Python Speedtest CLI..." && \
    # Make sure pip is installed
    # hadolint ignore=DL3008
    apt-get update && \
    # hadolint ignore=DL3008
    apt-get install -y --no-install-recommends python3-pip python3-setuptools python3-venv && \
    # Create a virtual environment for our Python packages
    python3 -m venv /opt/venv && \
    # Install cloudflarepycli from PyPI in the virtual environment
    /opt/venv/bin/pip install --no-cache-dir cloudflarepycli && \
    # Create a wrapper script for our cfspeedtest command
    echo '#!/bin/bash' > /usr/local/bin/cfspeedtest && \
    echo '/opt/venv/bin/cfspeedtest "$@"' >> /usr/local/bin/cfspeedtest && \
    chmod +x /usr/local/bin/cfspeedtest && \
    # Cleanup
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Ookla Speedtest CLI directly from the binary release
# hadolint ignore=DL3003
RUN echo "Installing Ookla Speedtest CLI (binary)..." && \
    { \
        set +e; \
        # Download the binary package directly
        # hadolint ignore=DL3003
        mkdir -p /tmp/speedtest && \
        # hadolint ignore=DL3003
        cd /tmp/speedtest && \
        # Try to download the latest version
        curl -fsSL --retry 3 --retry-delay 2 https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz \
            -o speedtest.tgz && \
        tar -xzf speedtest.tgz -C /tmp/speedtest && \
        # Install to /usr/local/bin
        if [ -f "/tmp/speedtest/speedtest" ]; then \
            mv /tmp/speedtest/speedtest /usr/local/bin/ && \
            chmod +x /usr/local/bin/speedtest && \
            # Accept license automatically for non-interactive environments
            mkdir -p /root/.config/ookla && \
            echo '{"Settings":{"LicenseAccepted": "604ec27f828456331ebf441826292c49276bd3c1bee1a2f65a6452f505c4061c"}}' > /root/.config/ookla/speedtest-cli.json; \
            echo "Successfully installed Ookla Speedtest CLI"; \
        else \
            echo "Warning: Failed to install Ookla Speedtest CLI - will use alternative only"; \
        fi && \
        # Clean up
        rm -rf /tmp/speedtest; \
        set -e; \
    }

# Configure SNMP to include custom MIBs
RUN echo "# SNMP configuration for custom MIBs" > /etc/snmp/snmp.conf && \
    echo "mibdirs /usr/share/snmp/mibs:/usr/share/snmp/mibs/custom" >> /etc/snmp/snmp.conf && \
    echo "mibs +ALL" >> /etc/snmp/snmp.conf && \
    chown root:root /etc/snmp/snmp.conf && \
    chmod 644 /etc/snmp/snmp.conf

# Cleanup
WORKDIR /
RUN echo "deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb http://archive.ubuntu.com/ubuntu noble-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://archive.ubuntu.com/ubuntu noble-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://security.ubuntu.com/ubuntu noble-security main restricted universe multiverse" >> /etc/apt/sources.list
# hadolint ignore=SC2015
RUN apt-get update && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/.cache/pip/* 2>/dev/null || true

# Install kubectl for Kubernetes management
# Download kubectl, verify the checksum, and install
RUN KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt) && \
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256" && \
    echo "$(cat kubectl.sha256) kubectl" | sha256sum --check && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl kubectl.sha256

# Copy custom scripts to Zabbix external scripts directory
COPY --chown=1997 --chmod=0711 ./scripts/* /usr/lib/zabbix/externalscripts/

# Copy custom SNMP MIBs (if any exist)
COPY --chown=1997 --chmod=0644 ./mibs/ /usr/share/snmp/mibs/custom/
# Remove README from the custom MIBs directory (not needed there)
RUN rm -f /usr/share/snmp/mibs/custom/README.md

# Set appropriate permissions
# hadolint ignore=SC2015
RUN chmod -R 755 /usr/local/bin/* && \
    # Create non-root directories with appropriate permissions
    mkdir -p /var/run/zabbix && \
    chown -R 1997:1997 /var/run/zabbix && \
    # Remove unnecessary setuid/setgid permissions
    find / -perm /6000 -type f -exec chmod a-s {} \; || true

# Add container labels
LABEL org.opencontainers.image.vendor="Zabbix" \
      org.opencontainers.image.title="Zabbix Proxy (SQLite3)" \
      org.opencontainers.image.description="Zabbix Proxy with SQLite3 database" \
      org.opencontainers.image.licenses="GPL v2.0"

# Switch back to Zabbix user (UID 1997)
USER 1997

# Define health check
# hadolint ignore=DL3047,DL4001
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --progress=dot:giga --tries=1 --spider 127.0.0.1:10051 || exit 1

# Create SBOM directory and file with appropriate permissions before switching users
USER root
RUN mkdir -p /usr/local/share && \
    touch /usr/local/share/zabbix-proxy-sbom.txt && \
    chown -R 1997:1997 /usr/local/share && \
    chmod 755 /usr/local/share && \
    chmod 664 /usr/local/share/zabbix-proxy-sbom.txt

# Switch back to Zabbix user
USER 1997

# Log versions of included tools for SBOM and traceability
# hadolint ignore=DL3047,DL4001
RUN echo "# SBOM: Included Tool Versions" > /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "# Core Monitoring Tools" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "zabbix-proxy-sqlite3: $(zabbix_proxy -V 2>&1 | head -1)" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "# Performance Testing Tools" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "ookla-speedtest: $(speedtest --version 2>&1 | head -1 || echo "Not installed - using Cloudflare alternative")" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "cloudflare-speedtest: $(/opt/venv/bin/cfspeedtest --version 2>&1 || echo "Installed via Python package cloudflarepycli")" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "# Network Diagnostic Tools" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "nmap: $(nmap --version | head -1)" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "fping: $(fping --version 2>&1 | head -1)" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "mtr: $(mtr --version 2>&1 | head -1)" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "traceroute: $(traceroute --version 2>&1 | head -1)" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "iproute2: $(ip -V 2>&1 | head -1)" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "tcpdump: $(tcpdump --version 2>&1 | head -1)" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "netcat: $(nc -h 2>&1 | head -1)" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "# Monitoring Protocol Tools" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "snmpwalk: $(snmpwalk --version 2>&1 | head -1)" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "custom MIBS directory: /usr/share/snmp/mibs/custom" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "# Kubernetes Management" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "kubectl: $(kubectl version --client --short 2>/dev/null | head -1)" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "# Data Processing Tools" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "jq: $(jq --version 2>&1)" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "jo: $(jo --version 2>&1 | head -1)" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "# Utility and System Tools" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "curl: $(curl --version | head -1)" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "wget: $(wget --version | head -1)" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "expect: $(expect -v 2>&1 | head -1)" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "nano: $(nano --version 2>&1 | head -1)" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "gnupg: $(gpg --version | head -1)" >> /usr/local/share/zabbix-proxy-sbom.txt
