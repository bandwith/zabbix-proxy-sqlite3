# 🔍 Zabbix Proxy SQLite3 for AV System Monitoring

[![Build & Push](https://github.com/bandwith/zabbix-proxy-sqlite3/actions/workflows/ci-release.yml/badge.svg)](https://github.com/bandwith/zabbix-proxy-sqlite3/actions/workflows/ci-release.yml)
[![GitHub Release](https://img.shields.io/github/v/release/bandwith/zabbix-proxy-sqlite3)](https://github.com/bandwith/zabbix-proxy-sqlite3/releases)
[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL%203.0-blue.svg)](LICENSE)

## 📋 Overview

A specialized Zabbix Proxy container built on SQLite3, enhanced and optimized for **Audio/Visual (AV) system monitoring**. This container extends the official Zabbix Proxy with additional monitoring tools, network utilities, and custom scripts specifically designed for AV infrastructure management.

### ✨ Key Features

- 🎯 **AV-Focused Monitoring**: Pre-configured for audio/visual systems
- 🛠️ **Extended Toolset**: Additional network diagnostics and monitoring utilities
- 📦 **Lightweight**: SQLite3 backend for simplified deployment
- 🔧 **Custom Scripts**: Ready-to-use monitoring scripts
- 🐳 **Container-Ready**: Optimized container image with health checks
- 🔒 **Security-Hardened**: Non-root execution with minimal attack surface

### 🏗️ Based On

- **Base Image**: [Official Zabbix Proxy SQLite3](https://hub.docker.com/r/zabbix/zabbix-proxy-sqlite3)
- **Original Work**: [Zabbix Community](https://github.com/zabbix)
- **Enhanced By**: [Hyperscale AV](https://github.com/HyperscaleAV)

---

## 🚀 Quick Start

### Docker Run

```bash
docker run -d \
  --name zabbix-proxy-av \
  --restart unless-stopped \
  -p 10051:10051 \
  -e ZBX_SERVER_HOST=your-zabbix-server.example.com \
  -e ZBX_HOSTNAME=av-proxy-01 \
  -e ZBX_PROXYMODE=0 \
  -e ZBX_SERVER_PORT=10051 \
  -e ZBX_PROXYBUFFERMODE=hybrid \
  -e ZBX_PROXYMEMORYBUFFERAGE=1800 \
  -e ZBX_PROXYMEMORYBUFFERSIZE=256M \
  -e ZBX_ENABLEREMOTECOMMANDS=1 \
  ghcr.io/bandwith/zabbix-proxy-sqlite3:latest
```

### Docker Compose

```yaml
---
services:
  zabbix-proxy:
    image: ghcr.io/bandwith/zabbix-proxy-sqlite3:latest
    container_name: zabbix-proxy-av
    restart: unless-stopped
    ports:
      - "10051:10051"
    environment:
      ZBX_SERVER_HOST: your-zabbix-server.example.com
      ZBX_HOSTNAME: av-proxy-01
      ZBX_PROXYMODE: 0
      ZBX_SERVER_PORT: 10051
      ZBX_PROXYBUFFERMODE: hybrid
      ZBX_PROXYMEMORYBUFFERAGE: 1800
      ZBX_PROXYMEMORYBUFFERSIZE: 256M
      ZBX_ENABLEREMOTECOMMANDS: 1
    volumes:
      - zabbix-db:/var/lib/zabbix
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "127.0.0.1:10051"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  zabbix-db:
```

> 💡 **Recommendation**: Deploy a Zabbix Agent alongside the Proxy for comprehensive monitoring.

---

## 📦 Available Versions

| Version | Container Tags | Zabbix Version | Support Status |
|---------|---------------|----------------|----------------|
| **7.0.13** | `lts`, `7.0.13`, `7.0` | 7.0 LTS | ✅ **Long-Term Support** |
| **7.2.7** | `latest`, `7.2.7`, `7.2` | 7.2 Stable | ✅ Latest Features |

> **📌 Note**: The `latest` tag points to the **highest version number (7.2.7)**, while the `lts` tag points to the **LTS version (7.0.13)** for maximum stability in production environments. Check the [Zabbix release notes](https://www.zabbix.com/release_notes) for detailed version differences.

### 🐳 Container Registries

#### GitHub Container Registry (Recommended)
```bash
# Pull the latest version (highest version number)
docker pull ghcr.io/bandwith/zabbix-proxy-sqlite3:latest

# Pull the LTS version (most stable)
docker pull ghcr.io/bandwith/zabbix-proxy-sqlite3:lts

# Pull a specific version
docker pull ghcr.io/bandwith/zabbix-proxy-sqlite3:7.0.13
```

## 🛠️ Enhanced Features

### 📡 Network Monitoring Tools
- **Connectivity**: `ping`, `traceroute`, `mtr`, `fping`
- **Discovery**: `nmap`, `netcat`, `dnsutils`
- **Analysis**: `tcpdump`, `iproute2`
- **Speed Testing**: Dual implementation with Cloudflare Speedtest and Ookla Speedtest CLI

### 🖥️ System Management
- **SNMP Monitoring**: Full SNMP toolkit with MIB support
- **Kubernetes**: `kubectl` for container orchestration monitoring
- **Data Processing**: `jq`, `jo` for JSON manipulation
- **Automation**: `expect` for interactive script automation

### 📝 Custom Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `k.sh` | Kubernetes command wrapper | Execute kubectl commands via Zabbix |
| `tcp-req.sh` | TCP request utility | Send custom TCP requests for testing |
| `pass-to-shell.sh` | Shell command passthrough | Execute system commands securely |

### 🔧 Configuration

#### Essential Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ZBX_SERVER_HOST` | *(required)* | Zabbix server hostname or IP |
| `ZBX_HOSTNAME` | *(required)* | Unique proxy identifier |
| `ZBX_PROXYMODE` | `0` | Proxy mode (0=active, 1=passive) |
| `ZBX_PROXYBUFFERMODE` | `hybrid` | Buffering strategy |
| `ZBX_ENABLEREMOTECOMMANDS` | `0` | Enable remote command execution |

#### Performance Tuning

| Variable | Default | Recommendation |
|----------|---------|----------------|
| `ZBX_PROXYMEMORYBUFFERSIZE` | `16M` | `256M` for AV systems |
| `ZBX_PROXYMEMORYBUFFERAGE` | `600` | `1800` for better buffering |

---

## 🏗️ Development & Contribution

### 🔄 Automated Workflows
- ✅ **Pre-commit hooks** for code quality assurance
- 🔄 **Mend Renovate** for dependency management
- 📝 **Automated documentation** updates for version changes
- 🏗️ **CI/CD pipeline** with multi-architecture builds
- 🚀 **Automatic releases** for each upstream Zabbix version
- 🏷️ **Smart versioning** with local change tracking

### 📦 Release Strategy

| Version Pattern | Description | Example |
|----------------|-------------|---------|
| `X.Y.Z` | **Upstream match** - Direct Zabbix version | `7.0.13` |
| `X.Y.Z.N` | **Local changes** - Incremented patch version | `7.0.13.1` |

**Automatic Release Creation**:
- 🎯 **New upstream versions** → Automatic release creation
- 🔧 **Local changes detected** → Patch version increment (e.g., `7.0.13` → `7.0.13.1`)
- 📋 **Release notes** → Generated with change summaries and usage instructions
- 🏷️ **Container tags** → Multiple tags per release (`latest`, `7.0`, `7.0.13`)

**Release Management**:
- 🎯 **LTS marking** → Latest major.0 version marked as "lts"
- 📋 **Manual releases** → Workflow dispatch for custom versions
- 🚀 **Automatic releases** when new Zabbix versions are detected

### 🛡️ Security Features
- 🚫 **Non-root execution** (UID 1997)
- 🔒 **Minimal attack surface** with cleaned dependencies
- 🔍 **Regular security scans** via automated tools
- � **Software Bill of Materials (SBOM)** in multiple formats:
  - Custom detailed SBOM with tool versions
  - SPDX format submitted to GitHub dependency graph
- �📋 **Health checks** for container monitoring

### 📋 System Requirements
- **Memory**: Minimum 512MB RAM (1GB+ recommended for AV environments)
- **Storage**: 100MB+ for container + data persistence volume
- **Network**: Access to Zabbix server on port 10051
- **Architecture**: linux/amd64, linux/arm64

---

## 📚 Documentation & Support

- 📖 [Official Zabbix Documentation](https://www.zabbix.com/documentation/)
- 🐛 [Issue Tracker](https://github.com/bandwith/zabbix-proxy-sqlite3/issues)
- 💬 [Discussions](https://github.com/bandwith/zabbix-proxy-sqlite3/discussions)
- 📧 [Contact](https://hyperscaleav.com/)

---

## 📄 License

This project is licensed under the **GNU AGPLv3** (Affero General Public License, version 3), following the Zabbix upstream license. See the [LICENSE](LICENSE) file for details.

> Portions of this project are derived from or based on [Zabbix](https://www.zabbix.com/), which is also licensed under the GNU AGPLv3.

---

## 🙏 Acknowledgments

- **Zabbix Community** for the excellent monitoring platform
- **Hyperscale AV** for the initial AV-focused enhancements
- **Contributors** who help improve this project

---

<div align="center">

**Built with ❤️ for the AV monitoring community**

[🌟 Star this repo](https://github.com/bandwith/zabbix-proxy-sqlite3) • [🐛 Report Bug](https://github.com/bandwith/zabbix-proxy-sqlite3/issues) • [💡 Request Feature](https://github.com/bandwith/zabbix-proxy-sqlite3/issues)

</div>
