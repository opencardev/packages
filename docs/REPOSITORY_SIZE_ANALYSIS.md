# Repository Size Issue Analysis and Solution

**Date**: 2026-01-20  
**Issue**: Packages repository growing continuously, causing CI file size issues

## Root Cause Analysis

### The Problem

The packages repository is experiencing unlimited growth because:

1. **Continuous Package Publishing**: Every commit triggers a build that publishes packages
2. **Multiple Architectures**: Each build creates 3 packages (amd64, arm64, armhf)
3. **Multiple Packages**: Each project has multiple packages (core, dev, etc.)
4. **No Cleanup**: Old package versions are never removed

### Current State

Examining the nightly repository shows:
- **crankshaft-core**: 60+ .deb files (20+ versions × 3 architectures)
- **libaasdk0**: 60+ .deb files (20+ versions × 3 architectures)
- Similar patterns for all other packages

**Example**: From Dec 13, 2025 to Jan 8, 2026 (26 days), we accumulated:
- 20+ versions of crankshaft-core
- 3 architectures per version
- Multiple commits per day
- Result: 60+ files for one package alone

### Growth Rate Calculation

Assuming:
- Average .deb file size: 2-5 MB
- 4 packages per project (core, ui, dev packages, etc.)
- 3 architectures per package
- 5 builds per day (conservative)

**Daily Growth**: 5 builds × 4 packages × 3 arch × 3 MB = ~180 MB/day  
**Monthly Growth**: 180 MB × 30 = ~5.4 GB/month  
**Annual Growth**: 5.4 GB × 12 = ~64.8 GB/year

This is unsustainable, especially for Git repositories which have practical limits.

## Solution Implemented

### 1. Automated Cleanup Workflow

**File**: `.github/workflows/cleanup-old-packages.yml`

**Features**:
- Runs daily at 03:00 UTC automatically
- Can be triggered manually with custom settings
- Supports dry-run mode for testing
- Separate handling for nightly vs stable packages

**Default Configuration**:
- **Nightly**: Keep last 10 versions (30 files per package)
- **Stable**: Keep last 20 versions (60 files per package)
- **Method**: Sort by modification time, remove oldest

### 2. Cleanup Process

The workflow:
1. Scans package directories in pool/
2. Identifies all .deb files per package
3. Sorts by modification time (newest first)
4. Keeps N most recent versions
5. Removes older versions
6. Regenerates package indices
7. Commits and pushes changes

### 3. Safety Features

- **Dry Run Mode**: Test without actually deleting
- **Conservative Defaults**: Stable packages kept longer
- **Separate Targets**: Clean nightly without affecting stable
- **Git History**: All removals are tracked in Git
- **Automatic Index Regeneration**: Ensures repository consistency

## Expected Impact

### With Default Settings (10 versions for nightly)

**Before Cleanup**:
- crankshaft-core: 60 files
- libaasdk0: 60 files
- crankshaft-ui: 60 files
- libaasdk-dev: 60 files
- **Total**: ~240 files

**After Cleanup**:
- crankshaft-core: 30 files (10 versions × 3 arch)
- libaasdk0: 30 files
- crankshaft-ui: 30 files
- libaasdk-dev: 30 files
- **Total**: ~120 files

**Result**: 50% reduction in package files

### Storage Savings

Assuming 3 MB average per .deb file:
- **Removed**: 120 files × 3 MB = 360 MB immediate savings
- **Ongoing**: Prevents ~150 MB/day accumulation
- **Monthly**: Saves ~4.5 GB/month from being added

## Deployment Steps

### 1. Immediate Actions

```bash
# First, run a dry-run to see what would be deleted
# Go to: https://github.com/opencardev/packages/actions
# Select: "Cleanup Old Packages"
# Configure:
#   - dry_run: true
#   - keep_versions: 10
#   - target_repo: nightly
```

### 2. Review Results

Check the action output to see:
- How many files would be removed
- Which versions would be kept
- Space that would be saved

### 3. Execute Cleanup

If satisfied with dry-run results:
```bash
# Run actual cleanup
#   - dry_run: false
#   - keep_versions: 10
#   - target_repo: nightly
```

### 4. Monitor

After cleanup:
- Check repository size: `du -sh packages/`
- Verify packages still work: Test installation
- Monitor future growth rate

## Recommendations

### Short Term (Immediate)

1. ✅ **Deploy cleanup workflow** (completed)
2. **Run initial cleanup**: Clean nightly to 10 versions
3. **Monitor for 1 week**: Ensure no issues reported
4. **Adjust if needed**: Increase/decrease retention based on feedback

### Medium Term (1-3 months)

1. **Optimize build frequency**: Consider not publishing every commit
2. **Implement staging**: Publish only tested builds
3. **Add size monitoring**: Alert when repository exceeds threshold
4. **Consider LFS**: Use Git LFS for large binary files

### Long Term (3-6 months)

1. **Archive old packages**: Move old versions to external storage
2. **Implement retention policies**: Different rules per package type
3. **Usage-based retention**: Keep frequently downloaded versions longer
4. **Separate repositories**: Split nightly and stable into different repos

## Alternative Solutions Considered

### 1. Git LFS (Large File Storage)

**Pros**: Better for binary files, reduces clone size  
**Cons**: Complexity, costs, doesn't solve growth problem  
**Decision**: Not implemented (cleanup is simpler)

### 2. Separate Package Repository

**Pros**: Doesn't bloat Git repository  
**Cons**: More infrastructure, hosting costs  
**Decision**: Consider for future if growth continues

### 3. On-Demand Package Building

**Pros**: Only build when requested  
**Cons**: Slower user experience, more complex  
**Decision**: Not implemented (unnecessary with cleanup)

## Monitoring and Maintenance

### Weekly Checks

```bash
# Check repository size
du -sh packages/

# Check package counts
find packages/pool -name "*.deb" | wc -l

# Check cleanup workflow runs
gh run list --workflow=cleanup-old-packages.yml --limit 10
```

### Monthly Reviews

1. Review retention settings
2. Check user feedback about missing packages
3. Adjust `keep_versions` if needed
4. Consider more aggressive cleanup if growth continues

### Alerts to Set Up

1. **Repository size > 2 GB**: Review cleanup settings
2. **Package count > 500**: Consider more aggressive cleanup
3. **Cleanup workflow failures**: Investigate immediately

## Documentation

### Created Files

1. `.github/workflows/cleanup-old-packages.yml` - Cleanup workflow
2. `docs/PACKAGE_CLEANUP.md` - Detailed cleanup documentation
3. `docs/REPOSITORY_SIZE_ANALYSIS.md` - This analysis document

### Updated Files

1. `README.md` - Added cleanup section

## Conclusion

The repository growth issue is caused by continuous package accumulation without removal. The implemented automated cleanup workflow will:

- **Reduce current size by ~50%**
- **Prevent future unbounded growth**
- **Maintain recent package availability**
- **Provide configurable retention policies**

The solution is:
- ✅ **Safe**: Dry-run mode, Git history
- ✅ **Automated**: Runs daily without intervention
- ✅ **Flexible**: Configurable retention and targets
- ✅ **Documented**: Clear guidelines and best practices

**Next Step**: Deploy the cleanup workflow and run an initial cleanup of nightly packages.
