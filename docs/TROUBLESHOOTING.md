# APT Repository Troubleshooting Guide

This guide helps you diagnose and fix common issues when using the OpenCarDev APT repository hosted at https://opencardev.github.io/packages.

If you prefer a quick checklist, jump to the Summary at the end.

## 1) Verify repository availability

- Check GitHub Pages is reachable:

```bash
curl -I https://opencardev.github.io/packages/
```

- List published distributions (expected: trixie, bookworm):

```bash
# Release metadata should exist per distribution
curl -fsSL https://opencardev.github.io/packages/dists/trixie/Release | head
curl -fsSL https://opencardev.github.io/packages/dists/bookworm/Release | head
```

If Release is missing, the distribution may not be published yet or Pages is still propagating. See section 6 (Propagation delays).

## 2) Verify GPG key and signatures

- Fetch and inspect the public key:

```bash
curl -fsSL https://opencardev.github.io/packages/opencardev.gpg.key | gpg --show-keys
```

- Install key into a dedicated system keyring (recommended):

```bash
sudo install -d -m 0755 /usr/share/keyrings
curl -fsSL https://opencardev.github.io/packages/opencardev.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/opencardev-archive-keyring.gpg
ls -l /usr/share/keyrings/opencardev-archive-keyring.gpg
```

## 3) Confirm client configuration (sources.list)

- Recommended single-line entry (auto-detects your architecture):

```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/opencardev-archive-keyring.gpg] https://opencardev.github.io/packages $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/opencardev.list
```

- For a specific suite (override auto-detection):

```bash
# Replace <suite> with trixie or bookworm
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/opencardev-archive-keyring.gpg] https://opencardev.github.io/packages <suite> main" | sudo tee /etc/apt/sources.list.d/opencardev.list
```

- Update and inspect output:

```bash
sudo apt update
```

If you see “does not have a Release file”, confirm the suite exists under dists/<suite>/Release (Section 1) and your sources line matches that suite exactly.

## 4) Check package indices and pool content

- Packages indices:

```bash
# Replace suite/arch as needed
curl -fsSL https://opencardev.github.io/packages/dists/trixie/main/binary-amd64/Packages | head -50
curl -fsSL https://opencardev.github.io/packages/dists/bookworm/main/binary-arm64/Packages | head -50
```

- Pool files present (typical paths):

```
https://opencardev.github.io/packages/pool/trixie/main/liba/
https://opencardev.github.io/packages/pool/bookworm/main/liba/
```

If indices or pool files are missing for a suite/arch, that combination may not have been published yet.

## 5) Architecture and multi-arch set-up

- Check your current architecture:

```bash
dpkg --print-architecture
```

- For foreign-arch installs (e.g., installing arm64 on an amd64 machine):

```bash
sudo dpkg --add-architecture arm64
sudo apt update
sudo apt install libaasdk:arm64 libaasdk-dev:arm64
```

If a foreign architecture is not enabled, apt will not see those packages.

## 6) Pages/CDN propagation delays

After the publishing workflow completes, GitHub Pages and CDN caches can take a few minutes to propagate. If Release or Packages is missing immediately after a successful publish, wait 2–5 minutes and try again. You can also force-refresh with curl using the full URL (avoid following redirects that may be cached differently).

## 7) Workflow and publishing checks

- Publishing workflow runs:
  - https://github.com/opencardev/packages/actions

- When publishing “all” distributions, a combined artifact is created and extracted (the workflow now supports both combined and per-distro artefacts).

- Collision protection: the workflow validates that new pool paths do not overwrite existing files with different content. If a collision is detected, the job fails with a clear error.

- If publish completes but Pages still shows old content, check the subsequent Pages deployment job and its logs.

## 8) Debian revision suffix expectations

We encode the distro in the Debian revision to prevent cross-suite collisions:

- Debian 12 (bookworm): `+deb12u1` (or `+deb12u2`, etc.)
- Debian 13 (trixie): `+deb13u1` (or higher)
- Ubuntu (future): `0ubuntu1~YY.MM` (e.g., `0ubuntu1~22.04`, `0ubuntu1~24.04`)

You can verify in CI (our pipelines assert these) or locally:

```bash
# For a downloaded .deb
dpkg-deb --field libaasdk_*.deb Version
```

If the suffix does not match the suite you published to, re-check the build environment suite and the packaging configuration.

## 9) Common errors and fixes

- “The repository … does not have a Release file”
  - Ensure the suite exists: `curl -fsSL https://opencardev.github.io/packages/dists/<suite>/Release`
  - Confirm your sources line uses that exact `<suite>`
  - Wait a couple of minutes for Pages to propagate, then retry `sudo apt update`

- “NO_PUBKEY …” / GPG key errors
  - Reinstall the key using the keyring method in Section 2
  - Ensure your sources entry includes `signed-by=/usr/share/keyrings/opencardev-archive-keyring.gpg`

- “Hash Sum mismatch”
  - Run `sudo apt clean && sudo apt update`
  - This can be a transient cache issue; if persistent, re-check the GitHub Pages deployment job logs

- “Package not found”
  - Check the Packages index for your suite+arch (Section 4)
  - Verify your architecture (Section 5)
  - Confirm the package name (runtime vs -dev)

## 10) Useful quick commands

```bash
# Show system suite and arch
lsb_release -cs; dpkg --print-architecture

# Show our sources entry
cat /etc/apt/sources.list.d/opencardev.list 2>/dev/null || true

# Fetch Release and Packages for your suite/arch
SUITE=$(lsb_release -cs)
ARCH=$(dpkg --print-architecture)
curl -fsSL "https://opencardev.github.io/packages/dists/${SUITE}/Release" | head
curl -fsSL "https://opencardev.github.io/packages/dists/${SUITE}/main/binary-${ARCH}/Packages" | head -50

# Inspect a local .deb
dpkg-deb --info libaasdk_*.deb | head -20
```

## Summary (quick checklist)

1. Confirm dists/<suite>/Release exists
2. Install key to /usr/share/keyrings and use signed-by in sources
3. Ensure your sources line matches your suite and arch
4. Check Packages indices for your suite/arch
5. Enable foreign architectures when needed
6. Allow 2–5 minutes for Pages/CDN propagation after publish
7. If CI failed on pool collision, increase the Debian revision suffix for the affected suite

If you’re still stuck, open an issue with:
- Your suite (e.g., bookworm), architecture (e.g., arm64), and the exact error output
- The output of `cat /etc/apt/sources.list.d/opencardev.list` (sanitised if necessary)
- Links to the relevant publish workflow run and Pages deployment
