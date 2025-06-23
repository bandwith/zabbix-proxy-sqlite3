# Building Historical Versions

This project provides a GitHub Action workflow to build historical Zabbix versions from 7.0.0 onward. This allows users to access previous Zabbix versions that may not be currently supported by upstream but could be needed for specific deployments.

## Using the Historical Build Workflow

1. Go to the GitHub repository's Actions tab
2. Select the "Build Historical Versions" workflow
3. Click "Run workflow"
4. Enter the minimum version to start building from (defaults to 7.0.0)
5. Optionally check "Force rebuild" to rebuild even if images already exist
6. Optionally provide a custom image name (e.g., "my-registry.com/user/repo")
7. Click "Run workflow" to start the process

The workflow will:
1. Fetch all available Zabbix versions from the Zabbix API
2. Filter versions to include only those >= the minimum specified version
3. Check which versions already exist in the GitHub Container Registry
4. For each selected version (e.g., 7.0.9), expand to include all previous patch releases in that series (7.0.0 through 7.0.9)
5. Build only versions that don't already exist (unless force rebuild is enabled)
6. Provide a summary of which versions were built, grouped by release series

## Available Historical Versions

After running the workflow, historical versions will be available with the following tag format:

### Default Image Name
By default, images will be published to the GitHub Container Registry:
```
ghcr.io/<repository-owner>/zabbix-proxy-sqlite3-av-edition:ubuntu-X.Y.Z
```

The image name will be automatically derived based on your repository name, ensuring compatibility when forking the repository. The workflow is intelligent enough to extract meaningful name components from your repository name.

### Custom Image Name
If you provide a custom image name (e.g., "my-registry.com/user/repo"), images will be published as:
```
my-registry.com/user/repo:ubuntu-X.Y.Z
```

Where X.Y.Z is the Zabbix version (e.g., 7.0.0, 7.0.1, etc.)

## Notes on Historical Versions

- Historical versions are provided as-is without support
- Only versions where the upstream Zabbix image exists can be built
- The workflow checks if the upstream images exist before attempting to build
- When you select a version like 7.0.9, the workflow will automatically expand this to build all patch releases in that series (7.0.0 through 7.0.9)
- This ensures complete coverage of all minor releases without having to manually specify each version
- You can specify a custom image name/location using the "custom_image_name" parameter (e.g., "my-registry.com/user/repo")

This feature is useful for:
- Environment consistency when upgrading gradually
- Testing compatibility with older Zabbix server versions
- Supporting legacy environments
