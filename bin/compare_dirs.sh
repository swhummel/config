#!/usr/bin/env bash

set -euo pipefail

RED='\033[31m'
YEL='\033[33m'
GRN='\033[32m'
RST='\033[0m'

# Maximum width for table path columns. Long values are trimmed at the start.
COL_WIDTH=46

usage() {
  cat <<'EOF'
Usage:
  compare_dirs.sh [OPTION] <directory1> <directory2>

Compares two directories recursively and prints:
1) A file overview table (left file, right file, status)
2) A detailed diff section for files that differ

Options:
  -i, --interactive-diff   Open each differing file in vimdiff (recommended name)
  -d, --show-diff          Print unified diff output for differing files
      --vimdiff            Alias for --interactive-diff
  -h, --help               Show this help

Status values in the first table:
  identical
  differs
  missing in <directory>

Examples:
  compare_dirs.sh ./dirA ./dirB
  compare_dirs.sh --show-diff ./dirA ./dirB
  compare_dirs.sh --interactive-diff ./dirA ./dirB
EOF
}

interactive_diff=0
show_diff=0

truncate_from_start() {
  local text="$1"
  local max_width="$2"

  if (( ${#text} <= max_width )); then
    printf '%s' "$text"
  else
    # Keep the end of long paths and mark truncation at the beginning.
    printf '...%s' "${text: -$((max_width - 3))}"
  fi
}

while (($# > 0)); do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -d|--show-diff)
      show_diff=1
      shift
      ;;
    -i|--interactive-diff|--vimdiff)
      interactive_diff=1
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Error: unknown option '$1'" >&2
      echo >&2
      usage >&2
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -ne 2 ]]; then
  echo "Error: expected exactly two directories." >&2
  echo >&2
  usage >&2
  exit 1
fi

dir1=$1
dir2=$2

if [[ ! -d "$dir1" ]]; then
  echo "Error: '$dir1' is not a directory." >&2
  exit 1
fi

if [[ ! -d "$dir2" ]]; then
  echo "Error: '$dir2' is not a directory." >&2
  exit 1
fi

if ((interactive_diff)) && ! command -v vimdiff >/dev/null 2>&1; then
  echo "Error: vimdiff is not available in PATH." >&2
  exit 1
fi

# Build a union of relative file paths from both directories.
declare -A left_files=()
declare -A right_files=()
declare -A all_files=()

while IFS= read -r rel_path; do
  left_files["$rel_path"]=1
  all_files["$rel_path"]=1
done < <(find "$dir1" -type f -printf '%P\n' | sort)

while IFS= read -r rel_path; do
  right_files["$rel_path"]=1
  all_files["$rel_path"]=1
done < <(find "$dir2" -type f -printf '%P\n' | sort)

mapfile -t sorted_paths < <(printf '%s\n' "${!all_files[@]}" | sed '/^$/d' | sort)

dir1_header="$(truncate_from_start "$dir1" "$COL_WIDTH")"
dir2_header="$(truncate_from_start "$dir2" "$COL_WIDTH")"

printf "%-${COL_WIDTH}s | %-${COL_WIDTH}s | %s\n" "$dir1_header" "$dir2_header" "status"
printf '%s\n' "$(printf '%.0s-' $(seq 1 "$COL_WIDTH"))-+-$(printf '%.0s-' $(seq 1 "$COL_WIDTH"))-+----------"

declare -a differing_paths=()

for rel_path in "${sorted_paths[@]}"; do
  left_path="$dir1/$rel_path"
  right_path="$dir2/$rel_path"

  left_label="missing"
  right_label="missing"
  status=""
  left_color="$RST"
  right_color="$RST"

  if [[ -n "${left_files[$rel_path]+x}" ]]; then
    left_label="$rel_path"
  fi

  if [[ -n "${right_files[$rel_path]+x}" ]]; then
    right_label="$rel_path"
  fi

  if [[ -n "${left_files[$rel_path]+x}" && -n "${right_files[$rel_path]+x}" ]]; then
    if cmp -s "$left_path" "$right_path"; then
      status="identical"
      left_color="$GRN"
      right_color="$GRN"
    else
      status="differs"
      left_color="$YEL"
      right_color="$YEL"
      differing_paths+=("$rel_path")
    fi
  elif [[ -n "${left_files[$rel_path]+x}" ]]; then
    status="missing"
    right_color="$RED"
  else
    status="missing"
    left_color="$RED"
  fi

  left_display="$(truncate_from_start "$left_label" "$COL_WIDTH")"
  right_display="$(truncate_from_start "$right_label" "$COL_WIDTH")"

  printf "%b%-${COL_WIDTH}s%b | %b%-${COL_WIDTH}s%b | %s\n" \
    "$left_color" "$left_display" "$RST" \
    "$right_color" "$right_display" "$RST" \
    "$status"
done

if ((${#differing_paths[@]} == 0)); then
  echo
  echo "No differing files found."
  exit 0
fi

if ((show_diff == 0 && interactive_diff == 0)); then
  echo
  echo "Diff output skipped. Use --show-diff or --interactive-diff."
  exit 0
fi

printf '\n%s\n' "==================== DIFF DETAILS ===================="

if ((interactive_diff)); then
  for rel_path in "${differing_paths[@]}"; do
    echo "Opening vimdiff for: $rel_path"
    vimdiff "$dir1/$rel_path" "$dir2/$rel_path"
  done
  exit 0
fi

printf "%-${COL_WIDTH}s | %s\n" "file" "diff"
printf '%s\n' "$(printf '%.0s-' $(seq 1 "$COL_WIDTH"))-+----------------------------------------"

for rel_path in "${differing_paths[@]}"; do
  diff_label="$(truncate_from_start "$rel_path" "$COL_WIDTH")"
  printf "%-${COL_WIDTH}s | shown below\n" "$diff_label"
  echo "----- BEGIN DIFF: $rel_path -----"
  diff -u --label "$dir1/$rel_path" --label "$dir2/$rel_path" "$dir1/$rel_path" "$dir2/$rel_path" || true
  echo "----- END DIFF: $rel_path -----"
  echo
done

