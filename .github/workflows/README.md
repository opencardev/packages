# APT Publishing Workflows

This directory contains GitHub Actions workflows for publishing OpenCarDev packages to the APT repository.

## Workflows

### 1. `apt-publish-aptly.yml` - Single Source Publishing
**Purpose**: Publishes packages from a single repository (either aasdk or openauto) to the APT repository.

**Inputs**:
- `source_repo`: Source repository (e.g., opencardev/aasdk)
- `build_run_id`: Specific build run ID to publish
- `distribution`: Target distribution (trixie, bookworm, all)
- `apt_category`: APT category (main, contrib, non-free)
- `apt_import`: Use APT import (true/false)
- `apt_glob`: Glob pattern for selecting .deb files

**Use Cases**:
- Publishing packages from a specific build run
- Quick publishing from a single repository
- Testing individual package builds

### 2. `apt-publish-multi-source.yml` - Multi-Source Publishing
**Purpose**: Publishes packages from both aasdk and openauto repositories simultaneously, with support for latest builds or specific run IDs.

**Inputs**:
- `aasdk_run_id`: AASDK build run ID (optional - uses latest if empty)
- `openauto_run_id`: OpenAuto build run ID (optional - uses latest if empty)
- `aasdk_workflow`: AASDK workflow name (default: "Build Packages")
- `openauto_workflow`: OpenAuto workflow name (default: "Build Release Package")
- `distribution`: Target distribution (trixie, bookworm, all)
- `apt_category`: APT category (main, contrib, non-free)
- `include_aasdk`: Include AASDK packages (true/false)
- `include_openauto`: Include OpenAuto packages (true/false)

**Use Cases**:
- Publishing complete package sets from both repositories
- Automated publishing using latest successful builds
- Selective publishing (aasdk only, openauto only, or both)
- Release management with coordinated package publishing

## Key Features of Multi-Source Workflow

### Automatic Latest Build Detection
- If no run ID is specified, automatically finds the latest successful build
- Uses GitHub API to query workflow runs by status
- Supports different workflow names for each repository

### Flexible Package Selection
- Can include/exclude AASDK packages
- Can include/exclude OpenAuto packages
- Supports publishing from one or both repositories

### Enhanced Organization
- Downloads artifacts from multiple sources
- Organizes packages by distribution and architecture
- Prevents package conflicts and collisions
- Maintains proper Debian package naming conventions

### Comprehensive Logging
- Detailed logging of source run IDs
- Package organization statistics
- Clear success/failure reporting
- Usage instructions in summary

## Usage Examples

### Publishing Latest Builds from Both Repositories
```yaml
# Trigger with defaults - will use latest successful builds
workflow_dispatch:
  inputs:
    distribution: "all"
    include_aasdk: true
    include_openauto: true
```

### Publishing Specific Build Runs
```yaml
workflow_dispatch:
  inputs:
    aasdk_run_id: "12345678"
    openauto_run_id: "87654321"
    distribution: "trixie"
```

### Publishing Only AASDK Packages
```yaml
workflow_dispatch:
  inputs:
    include_aasdk: true
    include_openauto: false
    distribution: "bookworm"
```

### Publishing with Custom Workflow Names
```yaml
workflow_dispatch:
  inputs:
    aasdk_workflow: "Custom Build"
    openauto_workflow: "Release Build"
    distribution: "all"
```

## Repository Structure

After successful publishing, packages are organized in the APT repository as:

```
packages/
├── dists/
│   ├── trixie/
│   │   └── main/
│   │       └── binary-{amd64,arm64,armhf}/
│   └── bookworm/
│       └── main/
│           └── binary-{amd64,arm64,armhf}/
├── pool/
│   └── main/
│       ├── a/aasdk/
│       └── o/openauto/
└── opencardev.gpg.key
```

## Package Installation

After publishing, users can install packages using:

```bash
# Add GPG key
curl -fsSL https://opencardev.github.io/packages/opencardev.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/opencardev-archive-keyring.gpg

# Add repository (choose your distribution)
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/opencardev-archive-keyring.gpg] https://opencardev.github.io/packages trixie main" | sudo tee /etc/apt/sources.list.d/opencardev.list

# Update and install
sudo apt update
sudo apt install libaasdk openauto-modern
```

## Secrets Required

Both workflows require the following repository secrets:
- `APT_SIGNING_KEY`: GPG private key for signing packages
- `APT_SIGNING_PASSPHRASE`: GPG key passphrase (optional)
- `GITHUB_TOKEN`: Automatically provided by GitHub Actions