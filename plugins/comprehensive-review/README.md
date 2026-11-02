# comprehensive-review (vendored)

Originally from [wshobson/agents](https://github.com/wshobson/agents) by Seth
Hobson, MIT licensed (see `LICENSE`). Copied into
`smartwatermelon/claude-code-workflows-agents` on 2026-07-31, and moved here on
2026-11-02.

- Upstream commit: `c4b82b0ad771190355eb8e204b1329732a18449a` (2026-07-18)
- Upstream path: `plugins/comprehensive-review/` (upstream version `1.3.1`)
- Plugin version: `1.3.1-swm.1`

## Why this exists

The commit-time review hook in `smartwatermelon/claude-config`
(`hooks/run-review.sh`) uses `comprehensive-review:comprehensive-review-code-reviewer`
as its default reviewer. It was the only plugin used from the 91 in
`wshobson/agents`. So it now lives here, not in a full copy of that repo.

The plugin keeps the name `comprehensive-review`, so existing
`comprehensive-review:<agent>` references keep resolving.

## What is included

Copied from upstream `plugins/comprehensive-review/`:

- `agents/architect-review.md`
- `agents/code-reviewer.md`
- `agents/security-auditor.md`
- `commands/full-review.md`
- `commands/pr-enhance.md`

## What is left out

- `.codex-plugin/` and the other non-Claude-Code harness files.
- Every other upstream plugin.

## Local changes to upstream files

Four, all from `smartwatermelon/claude-code-workflows-agents#3` (2026-07-31). A
sync must re-apply them. Each one shortens the `description` frontmatter to save
context; the bodies are unchanged.

1. `agents/architect-review.md`
2. `agents/code-reviewer.md`
3. `agents/security-auditor.md`
4. `commands/full-review.md`

The vendored Markdown is otherwise byte-identical to upstream. The repo-root
`.markdownlint-cli2.jsonc` exempts `plugins/comprehensive-review/agents/` and
`plugins/comprehensive-review/commands/` so it can stay that way.
