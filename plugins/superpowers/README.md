# superpowers (vendored subset)

A hook-less copy of part of [obra/superpowers](https://github.com/obra/superpowers)
by Jesse Vincent, MIT licensed (see `LICENSE`).

- Upstream commit: `8ca22dba9a94f28898bbce59f2537ff4d87c747d` (release v6.4.2)
- Plugin version: `6.4.2-swm.1`

## Why this exists

The upstream plugin ships a `SessionStart` hook (`hooks/session-start`) that
injects the `using-superpowers` skill into the context of every session.
Disabling it by hand does not survive plugin updates. This copy drops the hook,
so nothing is injected; the skills still load on demand.

The plugin keeps the name `superpowers`, so existing `superpowers:<skill>`
references keep resolving.

Background: [smartwatermelon/dev-env#126](https://github.com/smartwatermelon/dev-env/issues/126).

## What is included

Skills, copied from upstream `skills/` with every file in each directory:

- brainstorming
- executing-plans
- finishing-a-development-branch
- requesting-code-review
- subagent-driven-development
- systematic-debugging
- test-driven-development
- using-git-worktrees
- verification-before-completion
- writing-plans

## What is left out

- `hooks/` — the reason for this copy.
- `skills/using-superpowers` — the skill the hook injects.
- All other upstream skills (`writing-skills`, `dispatching-parallel-agents`,
  `receiving-code-review`, `diagnosing-superpowers`), and the non-Claude-Code
  harness files. `test-driven-development/writing-good-tests.md` still names
  `superpowers:writing-skills` in one aside; that reference does not resolve here.

## Local changes to upstream files

Two, both deliberate. A sync must re-apply them.

1. `skills/executing-plans/SKILL.md`: the pointer to
   `../using-superpowers/references/` is reworded, because that directory is
   not vendored.
2. `skills/subagent-driven-development/scripts/sdd-workspace`: `CDPATH= cd` is
   written `CDPATH='' cd` (two lines) to clear shellcheck SC1007. The behavior
   is the same.

The vendored skill Markdown is otherwise byte-identical to upstream. The
repo-root `.markdownlint-cli2.jsonc` exempts `plugins/superpowers/skills/` so
it can stay that way.

`skills/brainstorming/scripts/server.cjs` reads a version from the upstream
`package.json`, which this copy does not have. It reports `unknown`; nothing
else depends on it.
