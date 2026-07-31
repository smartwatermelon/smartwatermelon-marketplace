# Plan: Consolidating smartwatermelon's Claude Code plugins/skills/marketplaces

**Status**: Proposed — not scheduled. This document is a plan for future work, not
an in-flight migration. No repos have been touched as part of writing this.

## Why

Claude Code plugin/skill/marketplace content is currently spread across 7
repos in the `smartwatermelon` org, registered under up to 5 separate
marketplace names. There's no single place to see "everything Andrew has
published for Claude Code." This plan proposes a target end-state and a
staged path to get there, without breaking existing installs or losing the
ability to track upstream forks.

## Current inventory

Surveyed all non-archived repos under `smartwatermelon`. Only these are
Claude Code plugin/skill/marketplace-related:

| Repo | Role today | `.claude-plugin/marketplace.json` | `.claude-plugin/plugin.json` (root) | Notes |
| --- | --- | --- | --- | --- |
| **smartwatermelon-marketplace** (this repo) | Marketplace, 3 first-party plugins | Yes — `code-critic`, `react-native-3d`, `ci-workflows`, all `source: ./plugins/<name>` | No (per-plugin) | Target consolidation repo |
| **personify** | Marketplace + single plugin | Yes — 1 plugin, `source: ./` | Yes | Root `SKILL.md`; first-party, fully owned |
| **pr-review** | Marketplace + single plugin | Yes — 1 plugin, `source: ./` | Yes | Root `SKILL.md`; first-party, fully owned; near-identical layout to personify |
| **superpowers** | Marketplace + single large plugin | Yes (`superpowers-dev`) | Yes — author/homepage still `obra/superpowers` | Fork of `obra/superpowers`; 50-file `skills/` dir (TDD, debugging, brainstorming, etc.); tracks upstream |
| **superpowers-marketplace** | Marketplace only, no code | Yes — 10 plugin entries | N/A | Fork of `obra/superpowers-marketplace`; 9/10 entries still point at `github.com/obra/*`, only the `superpowers` entry repoints to `smartwatermelon/superpowers` |
| **claude-code-workflows-agents** | Marketplace, 95 sub-plugins | Yes (`claude-code-workflows`) | No (root); each of 95 sub-plugins has its own | Fork of `wshobson/agents`; large, multi-harness (also emits Codex/Cursor/Gemini extension manifests); tracks upstream |
| **claude-config** | Not a plugin — the orchestration/registry repo | No | No | Documents/symlinks all of the above into `~/.claude`; has a git submodule at `plugins/marketplaces/superpowers-marketplace`; its README is the current de facto "index" of all marketplaces |

Explicitly **not** in scope (checked, not plugin/skill/marketplace repos):
`dev-env` (pure spec/docs, states in its own README it isn't installable),
`claude-wrapper` (CLI wrapper binary, no plugin manifest anywhere).

## Constraint: how Claude Code actually resolves plugins

This shapes what "consolidation" can mean. From the plugin-marketplace docs:

- A `marketplace.json`'s `plugins[].source` can be a **relative path** (same
  repo only, must start with `./`, no `..`), or an external **`github`**,
  **`url`**, **`git-subdir`**, or **`npm`** reference. Relative paths only
  resolve when the marketplace itself was added via git/local-dir (not a bare
  `marketplace.json` URL).
- A marketplace **cannot nest another marketplace's plugin list** — every
  plugin must be listed individually in the top-level `plugins` array, even
  if its actual code lives in a different repo.
- Renaming a plugin's `name` or a marketplace's `name` breaks every existing
  install silently unless a `renames` map is added — and `renames` only
  covers plugins moving **within the same marketplace.json**, not plugins
  moving to a different marketplace entirely. Users who installed
  `personify@personify` will not automatically pick up
  `personify@smartwatermelon-marketplace`; that requires them to manually
  add the new marketplace and reinstall, and remove the old one.
- Forks that track an upstream repo (`superpowers`,
  `claude-code-workflows-agents`) benefit from staying as **separate git
  repos** — folding their code into this repo would make `git fetch upstream
  && rebase`-style syncing much harder, since the code would no longer sit at
  the upstream's repo root.

So true physical consolidation is cheap and safe for **first-party,
non-forked** content, and expensive/risky for **upstream-tracking forks**.
The plan splits accordingly.

## Proposed target state

### Tier 1 — physically merge into `smartwatermelon-marketplace`

Move these into `plugins/<name>/` in this repo, as new relative-path entries
in this repo's `marketplace.json`, alongside the existing `code-critic`,
`react-native-3d`, `ci-workflows`:

- **personify** (`plugins/personify/`)
- **pr-review** (`plugins/pr-review/`)

Both are already structured as single-plugin repos with root `SKILL.md` +
`.claude-plugin/plugin.json`, so the copy is close to mechanical (see
Migration steps below). After the move, mark the standalone `personify` and
`pr-review` repos **archived**, with their README rewritten to a one-line
pointer at the new location and install command. Keep the repos (don't
delete) so existing forks/links/history remain resolvable — GitHub archive
is enough, no need to unpublish.

### Tier 2 — keep as separate repos, cross-reference only

Do **not** physically merge, because both actively track an upstream fork:

- **superpowers** — stays at `smartwatermelon/superpowers`, keeps tracking
  `obra/superpowers`.
- **claude-code-workflows-agents** — stays as-is, keeps tracking
  `wshobson/agents`. At 95 sub-plugins and 1159 files this is also simply too
  large to fold in without becoming the tail wagging the dog of this repo.

For visibility, add **reference entries** for these to this repo's
`marketplace.json` using `github` source pointers (not relative paths), so
`/plugin install superpowers@smartwatermelon-marketplace` works as an alias
without moving code:

```jsonc
{
  "name": "superpowers",
  "source": { "source": "github", "repo": "smartwatermelon/superpowers" },
  "description": "Agentic skills framework (TDD, debugging, brainstorming, ...)",
  "category": "workflow"
}
```

Do the same for a representative entry point into
`claude-code-workflows-agents` if desired, or simply document it in this
repo's README rather than adding all 95 sub-plugins as entries (that would
duplicate the upstream's own marketplace catalog for little benefit).

### `superpowers-marketplace`: candidate for retirement

This repo is a marketplace-only fork of `obra/superpowers-marketplace`;
9 of its 10 entries are unmodified pointers to `obra/*` repos, and the 10th
(`superpowers`) is now redundant with the Tier 2 reference entry above. If
audit confirms Andrew doesn't need the other 9 obra plugins independently
versioned from upstream, **archive this repo** and drop the corresponding
submodule/marketplace registration from `claude-config`. If any of those 9
obra plugins are actually in active use, keep this repo but document it
explicitly as "third-party pass-through, not smartwatermelon-authored" in
the new consolidated README, rather than pretending it's part of the
first-party catalog.

### Repos unaffected

`dev-env`, `claude-wrapper`, `claude-config` — no plugin/marketplace changes.
`claude-config`'s README (the current de facto index) should be updated
*after* the above lands, to point at the new single marketplace as the
canonical list of first-party plugins, with Tier 2/retired items called out
explicitly.

## End state summary

One marketplace (`smartwatermelon-marketplace`) listing:

- `code-critic`, `react-native-3d`, `ci-workflows` (already here)
- `personify`, `pr-review` (physically migrated)
- `superpowers` (referenced via `github` source, code stays in its own repo)
- optionally a pointer/doc-only mention of `claude-code-workflows-agents`

One README that answers "what has Andrew published for Claude Code and how
do I install it" without needing `claude-config` as a decoder ring.

## Migration steps (for whenever this is executed)

1. **Tier 1 moves** (personify, pr-review), each as its own branch/PR:
   - `git subtree add` (or plain copy, given small repo size) the source
     repo's plugin content into `plugins/<name>/` here, preserving
     `.claude-plugin/plugin.json` as-is.
   - Add a `plugins[]` entry to this repo's `marketplace.json` with
     `source: ./plugins/<name>`, matching existing entry conventions
     (author, license, keywords aligned with the plugin's own `plugin.json`
     per this repo's existing keyword-drift lesson).
   - Update this repo's README "Available Plugins" section.
   - Run `claude plugin validate .` against the whole marketplace and
     against the new plugin dir individually.
   - Bump `smartwatermelon-marketplace` version per existing version-sync
     convention (marketplace.json + plugin.json + READMEs + CHANGELOG).
2. **Archive originals**: once the migrated plugin installs cleanly from
   the new location, replace the old repo's README with a pointer, then
   `gh repo archive smartwatermelon/personify` / `pr-review` (ask before
   archiving — irreversible-ish, and it's a repo setting change, not just a
   file edit).
3. **Tier 2 reference entries**: add the `github`-source entries for
   `superpowers` (and optionally `claude-code-workflows-agents`) to this
   repo's `marketplace.json`. No code moves. Validate as above.
4. **superpowers-marketplace disposition**: decide keep-vs-archive per the
   criteria above; if archiving, remove the corresponding submodule entry
   and registry line from `claude-config`.
5. **Update `claude-config`**: refresh its marketplace-registry section in
   README to reflect the new canonical structure, and update/remove the
   `plugins/marketplaces/superpowers-marketplace` submodule if that repo is
   archived.
6. **Communicate the migration** to any existing installs: since Claude
   Code's `renames` mechanism doesn't cover cross-marketplace moves, users
   who already ran `/plugin marketplace add smartwatermelon/personify` (or
   `pr-review`) need an explicit note (CHANGELOG + archived repo's README) to
   switch to `/plugin marketplace add smartwatermelon/smartwatermelon-marketplace`
   and reinstall under the new name — old installs won't silently redirect.

## Risks / open questions

- **Version pinning drift**: `personify` and `pr-review`'s existing
  `plugin.json` `version` fields need to be reconciled with this repo's
  independent versioning convention (memory: version numbers synced across
  marketplace.json/plugin.json/READMEs) — decide whether migrated plugins
  reset to `1.0.0` under the new marketplace or keep their prior version
  string.
- **No automatic user migration** for the two archived marketplaces (see
  step 6) — this is a one-time breaking change for anyone who installed
  from the old locations; low blast radius expected (personify/pr-review
  are single-user tools today) but worth confirming before archiving.
- **superpowers fork metadata**: `superpowers`'s `plugin.json` still lists
  `obra`/Jesse Vincent as author/homepage even though it's a smartwatermelon
  fork with behavioral diffs (forced SessionStart hook removed). Not a
  blocker for a reference-only marketplace entry, but worth deciding whether
  to correct authorship metadata independently of this consolidation.
- **claude-code-workflows-agents inclusion**: still undecided whether it's
  worth a marketplace-entry pointer at all, versus just a README mention,
  given it's a fork of third-party content (`wshobson/agents`) rather than
  original smartwatermelon work.
