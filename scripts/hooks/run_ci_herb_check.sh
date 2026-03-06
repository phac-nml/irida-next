#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <herb-script>" >&2
  echo "Example: $0 herb:lint" >&2
  exit 2
fi

herb_script="$1"
base_ref="${CI_PARITY_BASE_REF:-origin/main}"

declare -A seen
changed_erb_files=()

append_unique_files() {
  while IFS= read -r file_path; do
    [[ -n "$file_path" ]] || continue

    if [[ -z "${seen[$file_path]+x}" ]]; then
      seen["$file_path"]=1
      changed_erb_files+=("$file_path")
    fi
  done
}

append_unique_files < <(git diff --cached --name-only --diff-filter=ACMR -- "*.erb")

if git rev-parse --verify --quiet "$base_ref" > /dev/null; then
  merge_base="$(git merge-base HEAD "$base_ref")"
  append_unique_files < <(git diff --name-only --diff-filter=ACMR "${merge_base}...HEAD" -- "*.erb")
elif [[ ${#changed_erb_files[@]} -eq 0 ]]; then
  echo "Base ref '$base_ref' was not found locally and no staged ERB files changed; skipping ${herb_script}."
  exit 0
else
  echo "Base ref '$base_ref' was not found locally; checking staged ERB files only for ${herb_script}." >&2
  echo "Set CI_PARITY_BASE_REF or fetch '$base_ref' for full CI-parity checks." >&2
fi

if [[ ${#changed_erb_files[@]} -eq 0 ]]; then
  echo "No ERB files changed for CI-parity check; skipping ${herb_script}."
  exit 0
fi

pnpm run "$herb_script" "${changed_erb_files[@]}"
