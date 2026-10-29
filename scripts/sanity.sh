#!/usr/bin/env bash
# Sanity check: validate manifests and frontmatter, syntax-check plugin code.
set -euo pipefail
shopt -s globstar nullglob

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0
err() {
  echo "FAIL: $*" >&2
  fail=1
}

market="$root/.claude-plugin/marketplace.json"
jq -e '.name and (.plugins | type == "array" and length > 0)' "$market" >/dev/null || err "marketplace.json invalid"

rows="$(jq -r '.plugins[] | [.name, .source] | @tsv' "$market")"
while IFS=$'\t' read -r name source; do
  dir="$root/${source#./}"
  manifest="$dir/.claude-plugin/plugin.json"
  if [[ ! -d "$dir" ]]; then
    err "plugin $name: source $source missing"
    continue
  fi
  if [[ ! -f "$manifest" ]]; then
    err "plugin $name: $manifest missing"
    continue
  fi
  got="$(jq -r '.name // empty' "$manifest")" || {
    err "plugin $name: plugin.json is not valid JSON"
    continue
  }
  [[ "$got" == "$name" ]] || err "plugin $name: plugin.json name is '$got'"
  echo "ok plugin $name"
done <<<"$rows"

# Skills and agents need frontmatter with name and description.
for f in "$root"/plugins/**/SKILL.md "$root"/plugins/*/agents/*.md; do
  fm="$(awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1{print}' "$f")"
  grep -q '^name:' <<<"$fm" || err "$f: frontmatter lacks name"
  grep -q '^description:' <<<"$fm" || err "$f: frontmatter lacks description"
done

# Syntax-check shipped code.
for f in "$root"/plugins/**/*.js "$root"/plugins/**/*.cjs; do
  node --check "$f" || err "$f: JS syntax error"
done

for f in "$root"/plugins/**/*.sh; do
  bash -n "$f" || err "$f: bash syntax error"
done

exit "$fail"
