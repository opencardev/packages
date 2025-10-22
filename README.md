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

## Supported Distributions

| Distribution | Codename | Status |
|--------------|----------|---------|
| Debian 13    | trixie   | ✅ Active |

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
apt list --upgradable | grep opencardev

# Or search for specific packages
apt search libaasdk
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

```
packages/
├── dists/                  # Distribution metadata
│   ├── trixie/
│   ├── bookworm/
│   └── bullseye/
├── pool/                   # Package files
│   └── main/
│       ├── a/aasdk/
│       └── o/openauto/
├── opencardev.gpg.key     # Public GPG key
└── README.md              # This file
```

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

- **Key ID**: `8B4D82E3A38531F9B52CB481B1EDEA3B89921E78`
- **Fingerprint**: `8B4D 82E3 A385 31F9 B52C  B481 B1ED EA3B 8992 1E78`
- **Download**: https://opencardev.github.io/packages/opencardev.gpg.key

## License

This repository and its contents are licensed under the GNU General Public License v3.0.
Individual packages may have their own licenses - please refer to the package documentation.

## Support

- **Documentation**: [OpenCarDev Wiki](https://github.com/opencardev/aasdk/wiki)
- **Issues**: [GitHub Issues](https://github.com/opencardev/packages/issues)
- **Discussions**: [GitHub Discussions](https://github.com/opencardev/aasdk/discussions)

---

*Last updated: October 2025*