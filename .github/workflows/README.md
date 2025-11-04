# APT Publishing Workflows

This directory contains GitHub Actions workflows for publishing OpenCarDev packages to the APT repository.

## Available Workflows

### 1. `apt-publish-aptly.yml` - Single Source Publishing
**Purpose**: Publishes packages from a single repository (either aasdk or openauto) to the APT repository.

**Inputs**:
- `source_repo`: Source repository (e.g., opencardev/aasdk)
- `build_run_id`: Specific build run ID to publish
- `distribution`: Target distribution (trixie, bookworm, all)
- `apt_category`: APT category (main, contrib, non-free)
- `apt_import`: Use APT import (true/false)
- `apt_glob`: Glob pattern for selecting .deb files

**Trigger Methods**:
- Manual workflow dispatch
- Repository dispatch from other workflows
- Workflow call from other repositories

**Use Cases**:
- Publishing packages from a specific build run
- Quick publishing from a single repository
- Automated publishing triggered by build workflows
- Testing individual package builds

### 2. `apt-publish-multi-source-enhanced.yml` - Multi-Source Publishing
**Purpose**: Publishes packages from both aasdk and openauto repositories simultaneously, with automatic latest build detection and enhanced features.

**Inputs**:
- `aasdk_run_id`: AASDK build run ID (optional - uses latest if empty)
- `openauto_run_id`: OpenAuto build run ID (optional - uses latest if empty)  
- `aasdk_workflow`: AASDK workflow name (default: "Build Packages")
- `openauto_workflow`: OpenAuto workflow name (default: "Build Release Package")
- `distribution`: Target distribution (trixie, bookworm, all)
- `apt_category`: APT category (main, contrib, non-free)
- `include_aasdk`: Include AASDK packages (true/false)
- `include_openauto`: Include OpenAuto packages (true/false)

**Trigger Methods**:
- Manual workflow dispatch only

**Use Cases**:
- Publishing complete package sets from both repositories
- Automated publishing using latest successful builds
- Selective publishing (aasdk only, openauto only, or both)
- Release management with coordinated package publishing
- Manual release coordination for stable versions

## Key Features Comparison

| Feature | Single Source | Multi-Source Enhanced |
|---------|---------------|----------------------|
| **Source Repositories** | One (AASDK or OpenAuto) | Both (AASDK and OpenAuto) |
| **Run ID Specification** | Required | Optional (auto-detects latest) |
| **Latest Build Detection** | ❌ | ✅ (GitHub API integration) |
| **Package Selection** | All from source | Selective inclusion per source |
| **Automation Support** | ✅ (repository dispatch) | ❌ (manual only) |
| **Workflow Call Support** | ✅ | ❌ |
| **Enhanced Organization** | Basic | Advanced with conflict detection |
| **Multi-Job Architecture** | Single job | 5-job pipeline |
| **Detailed Reporting** | Basic | Comprehensive with usage instructions |

## Multi-Source Enhanced Features

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

### Using Single Source Workflow

**Publishing from AASDK build:**
```yaml
workflow_dispatch:
  inputs:
    source_repo: "opencardev/aasdk"
    build_run_id: "12345678"
    distribution: "all"
```

**Publishing from OpenAuto build:**
```yaml
workflow_dispatch:
  inputs:
    source_repo: "opencardev/openauto"
    build_run_id: "87654321"
    distribution: "trixie"
```

### Using Multi-Source Enhanced Workflow

**Publishing latest builds from both repositories:**
```yaml
workflow_dispatch:
  inputs:
    distribution: "all"
    include_aasdk: true
    include_openauto: true
```

**Publishing specific build runs:**
```yaml
workflow_dispatch:
  inputs:
    aasdk_run_id: "12345678"
    openauto_run_id: "87654321"
    distribution: "trixie"
```

**Publishing only AASDK packages:**
```yaml
workflow_dispatch:
  inputs:
    include_aasdk: true
    include_openauto: false
    distribution: "bookworm"
```

**Publishing with custom workflow names:**
```yaml
workflow_dispatch:
  inputs:
    aasdk_workflow: "Build Packages"
    openauto_workflow: "Build Release Package"
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

---

*For more information about OpenCarDev packages and installation, visit the [OpenCarDev documentation](https://github.com/opencardev).*
