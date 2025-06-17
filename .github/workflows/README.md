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
- When changes are pushed to the `main` branch affecting the `Dockerfile`, `scripts/` directory, or the workflow itself
- Manually via the "Run workflow" button with option to force rebuild all containers

## Reusable Workflows

The CI process has been refactored into modular, reusable workflows with a leading underscore (`_`) to differentiate them from main workflows:

- **_version-detection.yml**: Detects supported Zabbix versions and generates the build matrix
- **_check-changes.yml**: Determines if containers need rebuilding based on changes or schedule
- **_update-docs.yml**: Updates documentation with available Zabbix versions
- **_build-container.yml**: Builds, scans, and publishes Docker images for specific versions, generates SBOMs, and submits dependency data to GitHub
- **_cleanup.yml**: Handles cleanup of failed releases and tags

### Workflow Architecture

```
ci-release.yml (orchestrator)
  ↓
  ├─ _version-detection.yml
  ├─ _check-changes.yml
  ├─ _update-docs.yml
  └─ _build-container.yml (matrix strategy)
      └─ _cleanup.yml (on failure)
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
