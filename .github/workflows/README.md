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

The CI process has been refactored into modular, reusable workflows in the `reusable/` directory:

- **version-detection.yml**: Detects supported Zabbix versions and generates the build matrix
- **check-changes.yml**: Determines if containers need rebuilding based on changes or schedule
- **update-docs.yml**: Updates documentation with available Zabbix versions
- **build-container.yml**: Builds, scans, and publishes Docker images for specific versions
- **cleanup.yml**: Handles cleanup of failed releases and tags

### Workflow Architecture

```
ci-release.yml (orchestrator)
  ↓
  ├─ version-detection.yml
  ├─ check-changes.yml
  ├─ update-docs.yml
  └─ build-container.yml (matrix strategy)
      └─ cleanup.yml (on failure)
```

## Supporting Workflows

- **pre-commit.yml**: Runs code quality checks using pre-commit hooks
