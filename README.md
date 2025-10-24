# OpenCarDev APT Repository

This repository hosts the official APT packages for OpenCarDev projects, including AASDK (Android Auto SDK) and OpenAuto.

## Quick Setup

### 1. Add the Repository

```bash
# Add the GPG key
curl -fsSL https://opencardev.github.io/packages/opencardev.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/opencardev-archive-keyring.gpg

# Add the repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/opencardev-archive-keyring.gpg] https://opencardev.github.io/packages $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/opencardev.list

# Update package lists
sudo apt update
```

### 2. Install Packages

```bash
# Install AASDK
sudo apt install libaasdk libaasdk-dev

# Install OpenAuto (when available)
sudo apt install openauto
```

#### Installing for a specific architecture

On multi-arch systems or when installing a foreign architecture, specify the architecture suffix using Debian's package:arch syntax, for example:

```bash
# Examples
sudo apt install libaasdk:arm64 libaasdk-dev:arm64   # 64-bit ARM
sudo apt install libaasdk:armhf libaasdk-dev:armhf   # 32-bit ARM
sudo apt install libaasdk:amd64 libaasdk-dev:amd64   # 64-bit x86
```

If you're installing a foreign architecture, ensure it's enabled first:

```bash
sudo dpkg --add-architecture arm64   # or armhf, amd64, etc.
sudo apt update
```

## Supported Distributions

| Distribution | Codename | Status |
|--------------|----------|---------|
| Debian 13    | trixie   | ✅ Active |
| Debian 12    | bookworm | ✅ Active |

## Supported Architectures

- **amd64**: Intel/AMD 64-bit systems
- **arm64**: ARM 64-bit systems (Raspberry Pi 4, Apple Silicon, etc.)
- **armhf**: ARM 32-bit hard-float systems (Raspberry Pi 3, etc.)

## Available Packages

### AASDK (Android Auto SDK)

| Package | Description |
|---------|-------------|
| `libaasdk` | Runtime library for Android Auto SDK |
| `libaasdk-dev` | Development headers and files |

## Repository Management

### Automated Package Publishing with Aptly

This repository uses **Aptly** via GitHub Actions to create properly structured, GPG-signed APT repositories. The workflow automatically:

- Downloads build artifacts from source repositories
- Creates distribution-specific APT repositories using Aptly
- Signs packages with GPG for security
- Deploys to GitHub Pages for public access
- Supports multiple architectures (amd64, arm64, armhf)

### Triggering Repository Updates

The APT repository can be updated in several ways:

#### 1. Manual Workflow Dispatch
```bash
# Trigger from the packages repository web interface
# Go to: https://github.com/opencardev/packages/actions
# Select "opencardev APT Repository Upload (Aptly)"
# Click "Run workflow" and provide:
# - Source repository: opencardev/aasdk
# - Build run ID: (from successful build)
# - Distribution: trixie, bookworm, or both
```

#### 2. GitHub CLI (Command Line)
```bash
# From packages repository
gh workflow run apt-publish-aptly.yml \
  --repo opencardev/packages \
  -f source_repo="opencardev/aasdk" \
  -f build_run_id="12345678" \
  -f distribution="trixie"

# From source repository (aasdk)
gh workflow run trigger-apt-publish.yml \
  --repo opencardev/aasdk \
  -f build_run_id="12345678" \
  -f distribution="trixie"
```

#### 3. Workflow Integration
```yaml
# Add to your build workflow to auto-publish packages
- name: Publish to APT Repository
  if: github.ref == 'refs/heads/main' && success()
  uses: opencardev/packages/.github/workflows/apt-publish-aptly.yml@main
  with:
    source_repo: ${{ github.repository }}
    build_run_id: ${{ github.run_id }}
    distribution: 'trixie'
  secrets: inherit
```

### Repository Features

- **GPG Signed**: All packages are cryptographically signed for security
- **Multi-Architecture**: Supports amd64, arm64, and armhf architectures
- **Multi-Distribution**: Separate repositories for Trixie and Bookworm
- **Automated**: Updates trigger GitHub Pages deployment automatically
- **Verified**: Package integrity verified during installation

#### Installation Example

```bash
# Install runtime library
sudo apt install libaasdk

# For development, install dev package
sudo apt install libaasdk-dev

# Verify installation
pkg-config --modversion aasdk
```

### OpenAuto (Coming Soon)

OpenAuto packages will be available in future releases.

## Repository Status

You can check the current status of the APT repository:

```bash
# Check if repository is accessible
curl -I https://opencardev.github.io/packages/

# Verify GPG key is available
curl -s https://opencardev.github.io/packages/opencardev.gpg.key | gpg --show-keys

# Test repository metadata (replace 'trixie' with your distribution)
curl -s https://opencardev.github.io/packages/dists/trixie/Release

# Check available packages
curl -s https://opencardev.github.io/packages/dists/trixie/main/binary-amd64/Packages
```

### Workflow Status

The latest repository updates are automated through GitHub Actions. You can check the workflow status at:
- **Workflow Runs**: https://github.com/opencardev/packages/actions
- **Pages Deployment**: https://github.com/opencardev/packages/deployments

## Manual Setup (Alternative Method)

If the quick setup doesn't work for your distribution, you can set up the repository manually:

### Step 1: Download and Install GPG Key

```bash
# Create keyring directory if it doesn't exist
sudo mkdir -p /usr/share/keyrings

# Download and install the GPG key
wget -qO- https://opencardev.github.io/packages/opencardev.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/opencardev-archive-keyring.gpg

# Verify the key was installed
gpg --list-keys --keyring /usr/share/keyrings/opencardev-archive-keyring.gpg
```

### Step 2: Add Repository Source

```bash
# Detect your distribution
DISTRO=$(lsb_release -cs)
ARCH=$(dpkg --print-architecture)

# Create the source list file
echo "deb [arch=$ARCH signed-by=/usr/share/keyrings/opencardev-archive-keyring.gpg] https://opencardev.github.io/packages $DISTRO main" | sudo tee /etc/apt/sources.list.d/opencardev.list

# Update package cache
sudo apt update
```

### Step 3: Verify Repository

```bash
# List available packages from OpenCarDev
apt list | grep libaasdk

# Search for available packages
apt search aasdk

# Show package information
apt show libaasdk
```

## Raspberry Pi Setup

For Raspberry Pi users, here's a complete setup example:

```bash
#!/bin/bash
# Raspberry Pi OpenCarDev Setup Script

# Update system
sudo apt update && sudo apt upgrade -y

# Install required dependencies
sudo apt install -y curl gnupg lsb-release

# Add OpenCarDev repository
curl -fsSL https://opencardev.github.io/packages/opencardev.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/opencardev-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/opencardev-archive-keyring.gpg] https://opencardev.github.io/packages $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/opencardev.list

# Update and install AASDK
sudo apt update
sudo apt install -y libaasdk libaasdk-dev

echo "OpenCarDev packages installed successfully!"
```

## Package Verification

All packages are signed with our GPG key. You can verify package integrity:

```bash
# Download package information
apt-cache show libaasdk

# Verify package signature (automatic when properly configured)
sudo apt install libaasdk  # This will verify signatures automatically

# Manual verification of downloaded packages
apt download libaasdk
dpkg-sig --verify libaasdk_*.deb
```

## Troubleshooting

### Common Issues

#### GPG Key Errors

If you see GPG key errors:

```bash
# Remove old key and repository
sudo rm -f /usr/share/keyrings/opencardev-archive-keyring.gpg
sudo rm -f /etc/apt/sources.list.d/opencardev.list

# Re-add using the setup steps above
```

#### Architecture Issues

If packages aren't available for your architecture:

```bash
# Check your architecture
dpkg --print-architecture

# Verify supported architectures
curl -s https://opencardev.github.io/packages/dists/$(lsb_release -cs)/Release | grep Architecture
```

#### Distribution Not Supported

If your distribution isn't supported, you can try using packages from a compatible distribution:

```bash
# For newer Debian/Ubuntu, try using bookworm packages
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/opencardev-archive-keyring.gpg] https://opencardev.github.io/packages bookworm main" | sudo tee /etc/apt/sources.list.d/opencardev.list
```

### Dependency Issues

If you encounter dependency issues:

```bash
# Fix broken dependencies
sudo apt --fix-broken install

# Install missing dependencies manually
sudo apt install libboost-all-dev libprotobuf-dev libusb-1.0-0-dev libssl-dev

# Then retry package installation
sudo apt install libaasdk
```

## Development Setup

For developers who want to build against AASDK:

```bash
# Install development packages
sudo apt install libaasdk-dev

# Verify pkg-config setup
pkg-config --cflags --libs aasdk

# Example CMake usage
find_package(PkgConfig REQUIRED)
pkg_check_modules(AASDK REQUIRED aasdk)

target_link_libraries(your_target ${AASDK_LIBRARIES})
target_include_directories(your_target PRIVATE ${AASDK_INCLUDE_DIRS})
target_compile_options(your_target PRIVATE ${AASDK_CFLAGS_OTHER})
```

## Repository Structure

This repository is automatically generated using **Aptly** and follows standard Debian repository conventions:

```
packages/
├── dists/                  # Distribution metadata (generated by Aptly)
│   ├── trixie/
│   │   ├── main/
│   │   │   └── binary-{amd64,arm64,armhf}/
│   │   │       ├── Packages      # Package index
│   │   │       └── Packages.gz   # Compressed index
│   │   ├── Release               # Signed release info
│   │   └── Release.gpg          # GPG signature
│   └── bookworm/               # Same structure for Bookworm
├── pool/                      # Package files (generated by Aptly)
│   └── main/
│       ├── a/aasdk/          # AASDK packages by architecture
│       └── o/openauto/       # OpenAuto packages (future)
├── .github/
│   └── workflows/
│       └── apt-publish-aptly.yml  # Automated publishing workflow
├── opencardev.gpg.key        # Public GPG signing key
├── LICENSE                   # Repository license
└── README.md                # This documentation
```

### Aptly Benefits

Using Aptly provides several advantages over manual repository creation:

- **Proper APT Structure**: Creates standard Debian repository layout
- **GPG Integration**: Seamless package and repository signing
- **Multi-Architecture**: Handles multiple CPU architectures efficiently
- **Metadata Generation**: Automatically creates all required APT metadata files
- **Validation**: Ensures repository integrity and compliance

## Building from Source

If you prefer to build packages from source:

```bash
# Clone the AASDK repository
git clone https://github.com/opencardev/aasdk.git
cd aasdk

# Build using Docker
./build.sh

# Or build natively
mkdir build && cd build
cmake ..
make -j$(nproc)
sudo make install
```

## Contributing

To contribute packages or report issues:

1. **Issues**: Report bugs or request packages at [opencardev/packages](https://github.com/opencardev/packages/issues)
2. **Source Code**: Main projects are at:
   - [opencardev/aasdk](https://github.com/opencardev/aasdk)
   - [opencardev/openauto](https://github.com/opencardev/openauto)

## Security

### GPG Key Information

- **Key ID**: `DDD61787D9360C2F`
- **Fingerprint**: `B4F9 E5D4 E41B 0CBE EADF  33CA DDD6 1787 D936 0C2F`
- **Name**: OpenCarDev UK (Apt Signing)
- **Download**: https://opencardev.github.io/packages/opencardev.gpg.key

### Package Signing

All packages in this repository are signed using Aptly with our GPG key. The signature verification happens automatically when you install packages with `apt`, providing assurance that:

- Packages haven't been tampered with
- Packages come from the official OpenCarDev source  
- Package integrity is maintained during download

## License

This repository and its contents are licensed under the GNU General Public License v3.0.
Individual packages may have their own licenses - please refer to the package documentation.

## Support

- **Documentation**: [OpenCarDev Wiki](https://github.com/opencardev/aasdk/wiki)
- **Issues**: [GitHub Issues](https://github.com/opencardev/packages/issues)
- **Discussions**: [GitHub Discussions](https://github.com/opencardev/aasdk/discussions)

---

*Last updated: October 24, 2025 - Updated for Aptly-based repository management*