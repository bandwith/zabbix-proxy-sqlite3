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

## Deprecated Workflows

The following workflows are kept for reference but have been disabled:

- **release.yml**: Replaced by ci-release.yml
- **manual-release.yml**: Replaced by ci-release.yml
- **build-and-push.yml**: Replaced by ci-release.yml
- **update-versions.yml**: Functionality integrated into ci-release.yml

## Supporting Workflows

- **pre-commit.yml**: Runs code quality checks using pre-commit hooks
