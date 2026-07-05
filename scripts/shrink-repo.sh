#!/usr/bin/env bash
set -euo pipefail

# Shrinks repository footprint by removing files in pool/ that are not referenced
# by current dists/* Packages/Sources indexes.
#
# Default mode is dry-run.
# Usage:
#   scripts/shrink-repo.sh            # dry-run
#   scripts/shrink-repo.sh --apply    # delete unreferenced files
#   scripts/shrink-repo.sh --verbose  # print kept files

DRY_RUN=1
VERBOSE=0
REPO_ROOT=""

usage() {
  cat <<'EOF'
Usage: shrink-repo.sh [options]

Options:
  --apply            Actually delete unreferenced files from pool/
  --repo-root PATH   Repository root (default: script resolves parent dir)
  --verbose          Print additional details
  -h, --help         Show this help

What it does:
  1. Reads package indexes from dists/ (Packages, Packages.gz, Packages.xz,
     Sources, Sources.gz, Sources.xz)
  2. Extracts referenced file paths under pool/
  3. Deletes files in pool/ that are not referenced (or shows what would be deleted)

Safety:
  - Dry-run by default
  - Never deletes outside pool/
EOF
}

log() {
  printf '%s\n' "$*"
}

vlog() {
  if [[ "$VERBOSE" -eq 1 ]]; then
    printf '%s\n' "$*"
  fi
}

decompress_to_stdout() {
  local file="$1"
  case "$file" in
    *.xz) xz -dc -- "$file" ;;
    *.gz) gzip -dc -- "$file" ;;
    *) cat -- "$file" ;;
  esac
}

ensure_tools() {
  local missing=0
  for tool in awk find sort comm du; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      log "ERROR: required tool not found: $tool"
      missing=1
    fi
  done

  if ! command -v xz >/dev/null 2>&1; then
    log "ERROR: required tool not found: xz"
    missing=1
  fi

  if ! command -v gzip >/dev/null 2>&1; then
    log "ERROR: required tool not found: gzip"
    missing=1
  fi

  if [[ "$missing" -ne 0 ]]; then
    exit 1
  fi
}

resolve_repo_root() {
  if [[ -n "$REPO_ROOT" ]]; then
    REPO_ROOT="$(cd "$REPO_ROOT" && pwd)"
    return
  fi

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  REPO_ROOT="$(cd "$script_dir/.." && pwd)"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --apply)
        DRY_RUN=0
        shift
        ;;
      --repo-root)
        if [[ $# -lt 2 ]]; then
          log "ERROR: --repo-root requires a value"
          exit 1
        fi
        REPO_ROOT="$2"
        shift 2
        ;;
      --verbose)
        VERBOSE=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        log "ERROR: unknown option: $1"
        usage
        exit 1
        ;;
    esac
  done
}

extract_referenced_pool_paths() {
  local index_file="$1"

  decompress_to_stdout "$index_file" | awk '
    BEGIN {
      in_files = 0
      dir = ""
    }

    /^Filename:[[:space:]]+/ {
      path = $0
      sub(/^Filename:[[:space:]]+/, "", path)
      if (path ~ /^pool\//) {
        print path
      }
      in_files = 0
      next
    }

    /^Directory:[[:space:]]+/ {
      dir = $0
      sub(/^Directory:[[:space:]]+/, "", dir)
      in_files = 0
      next
    }

    /^Files:[[:space:]]*$/ {
      in_files = 1
      next
    }

    # Files block lines start with at least one space.
    in_files && /^[[:space:]]+/ {
      n = split($0, parts, /[[:space:]]+/)
      # Typical format after split: md5 size filename => filename at index n
      filename = parts[n]
      if (dir ~ /^pool\// && filename != "") {
        print dir "/" filename
      }
      next
    }

    # Any new stanza header ends Files block.
    /^[A-Za-z0-9-]+:[[:space:]]*/ {
      in_files = 0
      next
    }

    /^$/ {
      in_files = 0
    }
  '
}

main() {
  parse_args "$@"
  ensure_tools
  resolve_repo_root

  cd "$REPO_ROOT"

  if [[ ! -d "dists" || ! -d "pool" ]]; then
    log "ERROR: dists/ and pool/ must exist under repo root: $REPO_ROOT"
    exit 1
  fi

  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "${tmpdir:-}"' EXIT

  local referenced_file="$tmpdir/referenced.txt"
  local pool_file="$tmpdir/pool-files.txt"
  local delete_file="$tmpdir/to-delete.txt"

  : > "$referenced_file"

  while IFS= read -r index; do
    vlog "Scanning index: $index"
    extract_referenced_pool_paths "$index" >> "$referenced_file" || true
  done < <(find dists -type f \( -name 'Packages' -o -name 'Packages.gz' -o -name 'Packages.xz' -o -name 'Sources' -o -name 'Sources.gz' -o -name 'Sources.xz' \) | sort)

  sort -u "$referenced_file" -o "$referenced_file"

  find pool -type f | sed 's#^\./##' | sort > "$pool_file"

  comm -23 "$pool_file" "$referenced_file" > "$delete_file"

  local total_pool referenced_count delete_count
  total_pool=$(wc -l < "$pool_file" | tr -d ' ')
  referenced_count=$(wc -l < "$referenced_file" | tr -d ' ')
  delete_count=$(wc -l < "$delete_file" | tr -d ' ')

  log "Repository root: $REPO_ROOT"
  log "Pool files total: $total_pool"
  log "Referenced files: $referenced_count"
  log "Unreferenced files: $delete_count"

  log "Pool size before: $(du -sh pool | awk '{print $1}')"

  if [[ "$delete_count" -eq 0 ]]; then
    log "Nothing to delete. Repository is already compact for current indexes."
    exit 0
  fi

  if [[ "$VERBOSE" -eq 1 ]]; then
    log "Unreferenced files (first 200):"
    sed -n '1,200p' "$delete_file"
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY-RUN mode: no files deleted."
    log "Run with --apply to remove unreferenced files."
    exit 0
  fi

  log "Deleting unreferenced files from pool/..."
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    if [[ "$path" != pool/* ]]; then
      log "Skipping suspicious path (outside pool): $path"
      continue
    fi
    rm -f -- "$path"
  done < "$delete_file"

  # Remove now-empty directories to improve artifact compression.
  find pool -type d -empty -delete

  log "Pool size after: $(du -sh pool | awk '{print $1}')"
  log "Cleanup complete."
}

main "$@"
