#!/bin/bash

set -euo pipefail

# Output file
output_file="all_py_file_contents.txt"

# Default excludes (paths/patterns to avoid)
declare -a exclude_patterns=(
    ".git"
    "node_modules"
    "venv"
    "venv310"
    "__pycache__"
    "$output_file"
    "models"
    "node_modules"
)

# Usage:
#   ./collect_files.sh
#   ./collect_files.sh --exclude "*.ipynb" --exclude "backend/models/*"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --exclude|-e)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --exclude requires a pattern value." >&2
                exit 1
            fi
            exclude_patterns+=("$2")
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "Usage: $0 [--exclude <pattern>]..." >&2
            exit 1
            ;;
    esac
done

# Build tree ignore arg: tree expects patterns separated by "|"
tree_ignore=$(IFS='|'; echo "${exclude_patterns[*]}")

# Clear or create output file
> "$output_file"

# Save the tree output at the top
echo "===== Project Directory Structure =====" >> "$output_file"
tree -I "$tree_ignore" >> "$output_file"

# Separator
echo -e "\n\n===== Python File Contents Below =====" >> "$output_file"

# Use a temp file to store .py file paths
temp_file_list=$(mktemp)

# Build find pruning expression from exclude patterns
find_prune_args=()
for pattern in "${exclude_patterns[@]}"; do
    find_prune_args+=( -path "./$pattern" -o -path "./$pattern/*" -o -name "$pattern" -o )
done
unset 'find_prune_args[${#find_prune_args[@]}-1]'

# Get all .py files while honoring excludes
find . \( "${find_prune_args[@]}" \) -prune -o -type f -name "*.py" -print | sort > "$temp_file_list"

# Loop through each .py file path
while IFS= read -r file; do
    if [[ -f "$file" ]]; then
        echo -e "\n\nContents of: $file :" >> "$output_file"
        echo "=====================================" >> "$output_file"

        if file "$file" | grep -q text; then
            cat "$file" >> "$output_file"
        else
            echo "[Skipped: Not a text file]" >> "$output_file"
        fi
    fi
done < "$temp_file_list"

# Clean up temp file
rm "$temp_file_list"
