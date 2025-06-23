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
RUN apt-get update && \
    # Configure apt to prefer security repositories
    echo 'APT::Default-Release "noble";' > /etc/apt/apt.conf.d/99defaultrelease && \
    apt-get install -y --no-install-recommends \
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
    && apt-get upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Speedtest tools - both Cloudflare and Ookla (with fallbacks)
# hadolint ignore=DL3008,DL3003

# Install necessary dependencies
# hadolint ignore=DL3008
RUN apt-get update && \
    # Apply security updates
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    gnupg ca-certificates apt-transport-https curl dirmngr && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Cloudflare Speedtest Python CLI (cloudflarepycli)
# hadolint ignore=DL3008
WORKDIR /tmp
RUN echo "Installing Cloudflare Python Speedtest CLI..." && \
    # Make sure pip is installed
    # hadolint ignore=DL3008
    apt-get update && \
    # Apply security updates
    apt-get upgrade -y && \
    # hadolint ignore=DL3008
    apt-get install -y --no-install-recommends python3-pip python3-setuptools python3-venv && \
    # Create a virtual environment for our Python packages
    python3 -m venv /opt/venv && \
    # Install cloudflarepycli from PyPI in the virtual environment
    /opt/venv/bin/pip install --no-cache-dir cloudflarepycli && \
    # Update pip and dependencies in venv
    /opt/venv/bin/pip install --no-cache-dir --upgrade pip setuptools wheel && \
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

# Configure more secure apt sources with priority on security updates
WORKDIR /
# Check if ubuntu.sources exists and remove it to avoid duplication
RUN if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then \
      rm -f /etc/apt/sources.list.d/ubuntu.sources; \
    fi && \
    echo "deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb http://archive.ubuntu.com/ubuntu noble-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://archive.ubuntu.com/ubuntu noble-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "# Priority on security updates" >> /etc/apt/sources.list && \
    echo "deb http://security.ubuntu.com/ubuntu noble-security main restricted universe multiverse" >> /etc/apt/sources.list

# Create apt preferences file to prioritize security updates
RUN mkdir -p /etc/apt/preferences.d && \
    echo "Package: *" > /etc/apt/preferences.d/99-security-updates && \
    echo "Pin: release l=Ubuntu,o=Ubuntu,a=noble-security" >> /etc/apt/preferences.d/99-security-updates && \
    echo "Pin-Priority: 990" >> /etc/apt/preferences.d/99-security-updates && \
    # Create apt preferences to allow specific backports packages with high priority (equal to security)
    echo "Package: *" > /etc/apt/preferences.d/97-backports && \
    echo "Pin: release a=noble-backports" >> /etc/apt/preferences.d/97-backports && \
    echo "Pin-Priority: 990" >> /etc/apt/preferences.d/97-backports && \
    # Clean up apt lists to prevent duplicates
    rm -rf /var/lib/apt/lists/* && \
    # Disable apt translation files to reduce update size
    mkdir -p /etc/apt/apt.conf.d && \
    echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/99-no-translations

# Update and upgrade with security fixes
# hadolint ignore=SC2015,DL3008
RUN apt-get update && \
    apt-get upgrade -y && \
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

# Add container labels following OCI standards
# Note: Some dynamic labels like created date and revision are added by the workflow
LABEL org.opencontainers.image.title="Zabbix Proxy SQLite3 for AV Systems" \
      org.opencontainers.image.description="Zabbix Proxy with SQLite3 database for AV Systems" \
      org.opencontainers.image.licenses="AGPL-3.0" \
      org.opencontainers.image.vendor="Zabbix" \
      org.opencontainers.image.base.name="zabbix/zabbix-proxy-sqlite3"

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

# Final security updates before switching back to Zabbix user
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Switch back to Zabbix user
USER 1997

# Log versions of included tools for SBOM and traceability
# hadolint ignore=DL3047,DL4001
RUN echo "# SBOM: Included Tool Versions" > /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "# Generated: $(date -u +'%Y-%m-%d %H:%M:%S UTC')" >> /usr/local/share/zabbix-proxy-sbom.txt && \
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
    echo "kubectl: $(kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null || kubectl --version 2>/dev/null || echo "kubectl installed")" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "# Data Processing Tools" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "jq: $(jq --version 2>&1)" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "jo: $(jo -V 2>&1 || jo --version 2>&1 || echo "jo installed")" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "# Utility and System Tools" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "curl: $(curl --version | head -1)" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "wget: $(wget --version | head -1)" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "expect: $(expect -v 2>&1 | head -1)" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "nano: $(nano --version 2>&1 | head -1)" >> /usr/local/share/zabbix-proxy-sbom.txt && \
    echo "gnupg: $(gpg --version | head -1)" >> /usr/local/share/zabbix-proxy-sbom.txt
