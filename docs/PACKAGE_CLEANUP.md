# Package Cleanup Strategy

## Problem

The packages repository grows continuously as new package versions are published daily. Without cleanup, this leads to:
- Repository size issues (Git has practical limits)
- CI/CD performance degradation
- Increased storage costs
- Longer clone/fetch times

## Solution

An automated cleanup workflow that:
- Runs daily at 03:00 UTC
- Keeps the latest N versions per package
- Supports dry-run mode for testing
- Can target nightly, stable, or both repositories

## Configuration

### Default Settings

- **Nightly Repository**: Keep last 10 versions
- **Stable Repository**: Keep last 20 versions (more conservative)
- **Scheduled Run**: Daily at 03:00 UTC
- **Cleanup Target**: Nightly packages by default

### Manual Trigger Options

You can manually trigger the cleanup workflow with custom settings:

1. Go to Actions → Cleanup Old Packages
2. Click "Run workflow"
3. Configure:
   - **Keep versions**: Number of versions to retain (default: 10)
   - **Dry run**: Preview what would be deleted (default: false)
   - **Target repo**: Which repository to clean (nightly/stable/both)

## How It Works

### Version Retention

Packages are sorted by modification time (newest first), and the workflow:
1. Identifies all .deb files for each package
2. Keeps the most recent N versions
3. Removes older versions
4. Regenerates package indices
5. Commits and pushes changes

### Example

For `libaasdk0` with 60 versions and `keep_versions=10`:
- Keeps: 30 newest .deb files (10 versions × 3 architectures)
- Removes: 30 oldest .deb files
- Result: ~50% space reduction for that package

### Multi-Architecture Handling

Each version typically includes 3 architecture builds:
- `amd64` - Standard x86-64
- `arm64` - 64-bit ARM (Raspberry Pi 4/5)
- `armhf` - 32-bit ARM (older Raspberry Pi)

The cleanup treats each .deb file individually, so keeping "10 versions" actually retains up to 30 files per package.

## Best Practices

### For Development (Nightly)

- **Aggressive cleanup**: Keep 5-10 versions
- **Frequent runs**: Daily or even more frequent
- **Rationale**: Development moves fast; old nightly builds have little value

### For Production (Stable)

- **Conservative cleanup**: Keep 20-50 versions
- **Less frequent**: Weekly or monthly
- **Rationale**: Users may need to roll back to older stable versions

## Monitoring

### Repository Size

Check repository size regularly:

```bash
# Clone and check size
git clone https://github.com/opencardev/packages.git
du -sh packages/

# Check individual components
du -sh packages/pool/trixie/nightly/
du -sh packages/pool/trixie/stable/
```

### Cleanup Effectiveness

After each cleanup run:
1. Check the Actions summary for statistics
2. Monitor repository size over time
3. Adjust `keep_versions` if needed

## Safety Features

### Dry Run Mode

Always test with dry run first:
```yaml
inputs:
  dry_run: true
  keep_versions: '5'
  target_repo: 'nightly'
```

This shows what would be deleted without actually removing files.

### Separate Nightly/Stable

- Nightly and stable repositories are cleaned independently
- Stable repository has more conservative defaults (double retention)
- You can clean nightly without affecting stable

### No Data Loss

- Only removes old package versions
- Never removes the latest versions
- Package metadata is automatically regenerated
- All changes are committed to Git (can be reverted)

## Troubleshooting

### Cleanup Not Running

Check:
1. Workflow file syntax is valid
2. Schedule cron expression is correct
3. Repository permissions allow Actions to push

### Too Aggressive

If users report missing packages:
1. Increase `keep_versions` value
2. Check if stable packages were accidentally cleaned
3. Consider separate schedules for nightly vs stable

### Space Still Growing

If repository continues growing:
1. Reduce `keep_versions` further
2. Increase cleanup frequency
3. Consider monthly "deep clean" with very low retention
4. Archive old packages to external storage

## Future Improvements

Potential enhancements:
- Age-based cleanup (remove packages older than N days)
- Size-based cleanup (remove until total size < target)
- Automatic adjustment based on repository size
- Cleanup of orphaned metadata files
- Integration with package usage statistics
- Notification when cleanup removes many packages

## References

- Workflow: `.github/workflows/cleanup-old-packages.yml`
- APT Publishing: `.github/workflows/apt-publish-aptly.yml`
- APT Multi-Source: `.github/workflows/apt-publish-multi-source-enhanced.yml`
