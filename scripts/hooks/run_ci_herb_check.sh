#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <herb-script>" >&2
  echo "Example: $0 herb:lint" >&2
  exit 2
fi

herb_script="$1"
base_ref="${CI_PARITY_BASE_REF:-origin/main}"

if ! git rev-parse --verify --quiet "$base_ref" > /dev/null; then
  echo "Base ref '$base_ref' was not found locally." >&2
  echo "Set CI_PARITY_BASE_REF or fetch '$base_ref' before committing." >&2
  exit 1
fi

merge_base="$(git merge-base HEAD "$base_ref")"

declare -A seen
changed_erb_files=()

while IFS= read -r file_path; do
  [[ -n "$file_path" ]] || continue

  if [[ -z "${seen[$file_path]+x}" ]]; then
    seen["$file_path"]=1
    changed_erb_files+=("$file_path")
  fi
done < <(
  git diff --name-only --diff-filter=ACMR "${merge_base}...HEAD" -- "*.erb"
  git diff --cached --name-only --diff-filter=ACMR -- "*.erb"
)

if [[ ${#changed_erb_files[@]} -eq 0 ]]; then
  echo "No ERB files changed for CI-parity check; skipping ${herb_script}."
  exit 0
fi

pnpm run "$herb_script" "${changed_erb_files[@]}"
