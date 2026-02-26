#!/usr/bin/env bash
set -euo pipefail

# Guardrail: block newly introduced Tailwind utility class literals
# inside Pathogen component Ruby/ERB files.
BASE_BRANCH="${GITHUB_BASE_REF:-main}"
BASE_REF="origin/${BASE_BRANCH}"

if ! git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
  git fetch --no-tags --depth=1 origin "$BASE_BRANCH" >/dev/null 2>&1 || true
fi

if ! git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
  echo "Could not resolve ${BASE_REF}; skipping Pathogen Tailwind guardrail."
  exit 0
fi

DIFF_OUTPUT="$({
  git diff --unified=0 "${BASE_REF}...HEAD" -- \
    ':(glob)embedded_gems/pathogen/app/components/**/*.rb' \
    ':(glob)embedded_gems/pathogen/app/components/**/*.erb'
} | grep -E '^\+[^+]' || true)"

if [[ -z "$DIFF_OUTPUT" ]]; then
  echo "No new Pathogen component Ruby/ERB lines detected."
  exit 0
fi

# Match class-like literals that commonly indicate Tailwind utility usage.
TAILWIND_LITERAL_REGEX='["'"'"'][^"'"'"']*(dark:|text-|bg-|border-|rounded-|px-|py-|pl-|pr-|pt-|pb-|mx-|my-|mt-|mb-|ml-|mr-|flex|grid|font-|shadow-|ring-|gap-|space-x-|space-y-|items-|justify-)[^"'"'"']*["'"'"']'
VIOLATIONS="$(printf '%s\n' "$DIFF_OUTPUT" | grep -En "$TAILWIND_LITERAL_REGEX" || true)"

if [[ -n "$VIOLATIONS" ]]; then
  echo "Pathogen Tailwind guardrail failure: detected newly added Tailwind-like class literals."
  echo "Move new component styling to namespaced Pathogen classes/tokens instead."
  echo
  echo "$VIOLATIONS"
  exit 1
fi

echo "Pathogen Tailwind guardrail passed."
