# GitHub Workflows

## Active Workflows

### ci-release.yml (Primary Workflow)

This is the primary workflow for this repository. It handles:

1. **Version Detection**: Automatically detects and updates the list of supported Zabbix versions
2. **Container Building**: Builds and pushes Docker images for all supported versions
3. **Release Creation**: Creates GitHub releases with proper versioning
4. **Dependency Change Detection**: Automatically rebuilds containers when dependencies change

**When it runs:**
- Daily at midnight UTC
- When changes are pushed to the `main` branch affecting the `Dockerfile`, `scripts/` directory, `mibs/` directory, or the workflow itself
- Manually via the "Run workflow" button with option to force rebuild all containers

### build-historical-versions.yml (Historical Versions)

This workflow builds historical versions of Zabbix Proxy containers. It handles:

1. **Version Discovery**: Uses the Zabbix API to identify supported major.minor series
2. **Docker Hub Tag Scanning**: Scans Docker Hub for available tags matching supported series
3. **Conditional Building**: Only builds versions that don't exist in our registry but do exist upstream
4. **Patch Expansion**: Optionally builds all patch versions (0 to latest) for each major.minor series

**When it runs:**
- Manually via the "Run workflow" button with the following options:
  - Minimum version to start building from
  - Whether to force rebuild existing images
  - Optional custom image name
  - Whether to build all patch versions for each major.minor series

## Reusable Workflows

The CI process has been refactored into modular, reusable workflows with:
- Double underscore filenames (`__`) to sort them lower in the file list
- Display names with `◆ reusable |` prefix to sort them lower in the GitHub Actions UI

Reusable workflows:

- **__version-detection.yml**: Detects supported Zabbix versions from the Zabbix API
- **__dockerhub-tags.yml**: Retrieves available container tags from Docker Hub
- **__check-changes.yml**: Determines if containers need rebuilding based on changes or schedule
- **__update-docs.yml**: Updates documentation with available Zabbix versions
- **__build-container.yml**: Builds, scans, and publishes Docker images for specific versions, generates SBOMs, and submits dependency data to GitHub
- **__cleanup.yml**: Handles cleanup of failed releases and tags (used by ci-release.yml)

### Workflow Architecture

```
ci-release.yml (orchestrator)
  ↓
  ├─ __version-detection.yml
  ├─ __check-changes.yml
  ├─ __update-docs.yml
  └─ __build-container.yml (matrix strategy)
      └─ __cleanup.yml (on failure)

build-historical-versions.yml (historical builds)
  ↓
  ├─ __version-detection.yml
  ├─ __dockerhub-tags.yml
  └─ __build-container.yml (matrix strategy)
```

## Supporting Workflows

- **pre-commit.yml**: Runs code quality checks using pre-commit hooks

## Security and Compliance Features

### Software Bill of Materials (SBOM)

The build workflow includes comprehensive SBOM generation and reporting:

1. **Custom SBOM**: Generated during container build, containing versions of all critical components
   - Located in `/usr/local/share/zabbix-proxy-sbom.txt` within the container
   - Extracted and attached to GitHub releases

2. **SPDX SBOM**: Generated with Trivy in SPDX format
   - Submitted to GitHub's dependency graph via the `advanced-security/spdx-dependency-submission-action`
   - Provides automated vulnerability scanning through GitHub Dependabot
   - Attached to GitHub releases as `sbom-spdx.json`

3. **Validation**: Both SBOM formats are validated before release
   - Custom SBOM: Checks for required tools and components
   - SPDX SBOM: Validates structure and content
