# Git Hooks Integration Guide

This guide explains how to integrate the Code Critic adversarial-reviewer agent with git hooks for automated code review.

## Table of Contents

- [Overview](#overview)
- [Recommended Hooks](#recommended-hooks)
- [Pre-Commit Hook](#pre-commit-hook-strict-projects)
- [Pre-Push Hook](#pre-push-hook-recommended)
- [Commit-Msg Hook](#commit-msg-hook)
- [Advanced Patterns](#advanced-patterns)
- [Troubleshooting](#troubleshooting)

## Overview

Git hooks allow you to automatically run Code Critic reviews at key points in your development workflow:

- **pre-commit**: Review changes before they're committed
- **pre-push**: Review branch changes before pushing to remote
- **commit-msg**: Validate commit messages for completeness

### When to Use Which Hook

| Hook | Best For | Performance Impact |
|------|----------|-------------------|
| **pre-commit** | Security-critical projects | High (reviews every commit) |
| **pre-push** | Most projects | Medium (reviews before push) |
| **commit-msg** | Message validation | Low (no code review) |

**Recommendation**: Start with `pre-push` for best balance of thoroughness and developer velocity.

## Recommended Hooks

### Pre-Push Hook (Recommended)

Reviews all changes about to be pushed, catching issues before they reach the team.

Create `.git/hooks/pre-push`:

```bash
#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "🔍 Running Code Critic review..."

# Get the remote and branch being pushed to
remote="$1"
url="$2"

# Get commits that will be pushed
LOCAL_BRANCH=$(git rev-parse --abbrev-ref HEAD)
REMOTE_BRANCH=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "origin/$LOCAL_BRANCH")

# Check if remote branch exists
if ! git rev-parse "$REMOTE_BRANCH" >/dev/null 2>&1; then
  echo "📝 New branch - reviewing all changes"
  DIFF_BASE=$(git merge-base HEAD origin/main 2>/dev/null || git rev-list --max-parents=0 HEAD)
else
  DIFF_BASE="$REMOTE_BRANCH"
fi

# Get the diff
DIFF=$(git diff "$DIFF_BASE"...HEAD)

if [ -z "$DIFF" ]; then
  echo "${GREEN}✓ No changes to review${NC}"
  exit 0
fi

# Run review
echo "$DIFF" | claude --agent adversarial-reviewer \
  --no-session-persistence \
  -p "Review these changes before push. Focus on:
- Architectural concerns
- Failure modes
- Security implications
- Maintenance burden

Provide specific, actionable feedback."

REVIEW_EXIT=$?

if [ $REVIEW_EXIT -ne 0 ]; then
  echo "${RED}❌ Code Critic found issues${NC}"
  echo "Fix issues and try again. If review times out, retry or split into smaller commits."
  exit 1
fi

echo "${GREEN}✓ Code Critic review passed${NC}"
exit 0
```

Make it executable:

```bash
chmod +x .git/hooks/pre-push
```

### Pre-Commit Hook (Strict Projects)

Reviews staged changes before each commit. More thorough but slower.

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
set -e

# Only review certain file types
FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(ts|js|py|go|rs|java)$' || true)

if [ -z "$FILES" ]; then
  echo "No code files to review"
  exit 0
fi

echo "🔍 Reviewing staged changes..."

# Get staged diff
DIFF=$(git diff --cached)

# Run review
echo "$DIFF" | claude --agent adversarial-reviewer \
  --no-session-persistence \
  -p "Quick review of staged changes. Focus on critical issues only."

if [ $? -ne 0 ]; then
  echo "❌ Review found issues. Fix and retry, or split into smaller commits."
  exit 1
fi

echo "✓ Review passed"
exit 0
```

Make it executable:

```bash
chmod +x .git/hooks/pre-commit
```

## Selective Review Based on Files

Review only security-critical files:

```bash
#!/bin/bash
set -e

# Define critical patterns
CRITICAL_PATTERNS=(
  "*/auth/*"
  "*/payment/*"
  "*/security/*"
  "**/models/*"
  "**/schema/*"
)

# Check if any critical files changed
CRITICAL_FILES=""
for pattern in "${CRITICAL_PATTERNS[@]}"; do
  FILES=$(git diff --name-only origin/main...HEAD | grep -E "$pattern" || true)
  if [ -n "$FILES" ]; then
    CRITICAL_FILES="$CRITICAL_FILES$FILES"$'\n'
  fi
done

if [ -z "$CRITICAL_FILES" ]; then
  echo "No security-critical files changed"
  exit 0
fi

echo "🔒 Security-critical files detected, running adversarial review..."
echo "$CRITICAL_FILES"

git diff origin/main...HEAD | claude --agent adversarial-reviewer \
  --no-session-persistence \
  -p "Review these security-critical changes:

Critical files modified:
$CRITICAL_FILES

Focus on:
- Authentication/authorization flaws
- SQL injection risks
- XSS vulnerabilities
- Race conditions
- Data exposure"

if [ $? -ne 0 ]; then
  echo "❌ Security review failed"
  exit 1
fi

echo "✓ Security review passed"
exit 0
```

## Commit-Msg Hook

Ensures commit messages include security/architectural notes:

Create `.git/hooks/commit-msg`:

```bash
#!/bin/bash

COMMIT_MSG_FILE=$1
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Check if this is a security or architecture change
if git diff --cached --name-only | grep -qE '(auth|security|payment|schema|models)'; then
  # Verify commit message mentions security/architecture considerations
  if ! echo "$COMMIT_MSG" | grep -qiE '(security|auth|architecture|safety|vulnerability)'; then
    echo "❌ Security/architecture changes require mention of security considerations in commit message"
    echo ""
    echo "Your commit modifies security-critical files but doesn't mention:"
    echo "  - Security implications"
    echo "  - Architecture changes"
    echo "  - Safety considerations"
    echo ""
    echo "Add a note about security considerations to your commit message."
    exit 1
  fi
fi

exit 0
```

Make it executable:

```bash
chmod +x .git/hooks/commit-msg
```

## Advanced Patterns

### Global Git Hooks

Share hooks across all repositories:

1. Create global hooks directory:

   ```bash
   mkdir -p ~/.git-hooks
   ```

2. Configure git to use it:

   ```bash
   git config --global core.hooksPath ~/.git-hooks
   ```

3. Add hooks to `~/.git-hooks/pre-push`, etc.

### Project-Specific Hooks Extension

Create `.git-hooks/` in your repo with additional checks:

```bash
#!/bin/bash
# .git/hooks/pre-push

# Run standard Code Critic review
~/.git-hooks/pre-push "$@"

# Run project-specific checks
if [ -f .git-hooks/pre-push-local ]; then
  .git-hooks/pre-push-local "$@"
fi
```

### Parallel Review with Other Tools

Combine Code Critic with other review tools:

```bash
#!/bin/bash
set -e

echo "Running parallel reviews..."

# Run linter
eslint src/ &
ESLINT_PID=$!

# Run type checker
tsc --noEmit &
TSC_PID=$!

# Run Code Critic
git diff origin/main...HEAD | claude --agent adversarial-reviewer \
  --no-session-persistence \
  -p "Review architectural and failure mode concerns" &
CRITIC_PID=$!

# Wait for all
wait $ESLINT_PID
wait $TSC_PID
wait $CRITIC_PID

echo "✓ All reviews passed"
```

### Caching Review Results

Cache reviews to avoid re-reviewing unchanged code:

```bash
#!/bin/bash

# Get hash of changes
CHANGES_HASH=$(git diff origin/main...HEAD | shasum | cut -d' ' -f1)
CACHE_FILE=".git/code-critic-cache-$CHANGES_HASH"

if [ -f "$CACHE_FILE" ]; then
  echo "✓ Changes previously reviewed (cached)"
  exit 0
fi

# Run review
git diff origin/main...HEAD | claude --agent adversarial-reviewer \
  --no-session-persistence \
  -p "Review these changes"

if [ $? -eq 0 ]; then
  # Cache success
  touch "$CACHE_FILE"
  # Clean old cache files
  find .git -name 'code-critic-cache-*' -mtime +7 -delete
fi
```

### Skipping Review When Appropriate

Allow developers to skip when justified:

```bash
#!/bin/bash

# Check for skip marker in commit message
if git log -1 --pretty=%B | grep -q '\[skip-critic\]'; then
  echo "⏭️  Skipping Code Critic (commit message contains [skip-critic])"
  exit 0
fi

# Check for skip marker in environment
if [ "$SKIP_CODE_CRITIC" = "1" ]; then
  echo "⏭️  Skipping Code Critic (SKIP_CODE_CRITIC=1)"
  exit 0
fi

# Run normal review
# ...
```

Usage:

```bash
# Skip for this commit
git commit -m "docs: update README [skip-critic]"

# Skip for this push
SKIP_CODE_CRITIC=1 git push
```

## Integration with CI/CD

Run Code Critic in CI for backup review:

### GitHub Actions

```yaml
name: Code Critic Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - name: Install Claude Code
        run: |
          curl -fsSL https://cli.anthropic.com/install.sh | sh

      - name: Install Code Critic Plugin
        run: |
          claude plugin install github:smartwatermelon/code-critic-plugin

      - name: Run Review
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          git diff origin/${{ github.base_ref }}...HEAD | \
          claude --agent adversarial-reviewer \
            --no-session-persistence \
            -p "Review PR changes" \
            > review-output.txt

      - name: Comment PR
        if: always()
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const review = fs.readFileSync('review-output.txt', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## Code Critic Review\n\n${review}`
            });
```

## Troubleshooting

### Hook Not Running

Check if hook is executable:

```bash
ls -l .git/hooks/pre-push
# Should show: -rwxr-xr-x
```

Make it executable:

```bash
chmod +x .git/hooks/pre-push
```

### Hook Runs But Agent Not Found

Verify plugin installation:

```bash
claude plugin list | grep code-critic
```

Install if missing:

```bash
claude plugin install github:smartwatermelon/code-critic-plugin
```

### Review Too Slow

1. **Use pre-push instead of pre-commit** - Reviews only before push
2. **Review only critical files** - See "Selective Review" section
3. **Use Sonnet model** - Edit agent file: `model: sonnet` instead of `model: opus`
4. **Cache results** - See "Caching Review Results" section

### False Positives

Provide more context in the review prompt:

```bash
git diff origin/main...HEAD | claude --agent adversarial-reviewer \
  -p "Review changes. Context:
- This is a greenfield project, some patterns are intentionally experimental
- Performance is not critical (< 100 users)
- Focus on security and maintainability only"
```

### When Hooks Block You

If the review hook times out or fails unexpectedly:

1. **Retry the commit** — transient failures happen
2. **Increase timeout**: `git config review.timeout 300`
3. **Split into smaller commits** — smaller diffs review faster
4. **Check agent availability** — verify the plugin is installed

Do not use `--no-verify` to skip review hooks. The review exists to catch issues before they reach CI (which costs money). If you truly cannot proceed, have a human commit manually.

## Best Practices

1. **Start with pre-push** - Good balance of thoroughness and speed
2. **Review security-critical files with pre-commit** - Extra safety for auth, payments, etc.
3. **Provide context in prompts** - Better reviews with better context
4. **Allow skipping for emergencies** - But track and review later
5. **Cache results** - Avoid re-reviewing unchanged code
6. **Run in CI as backup** - Catch what local hooks might miss

## Further Reading

- [Usage Guide](USAGE.md)
- [Plugin README](../README.md)
- [Git Hooks Documentation](https://git-scm.com/docs/githooks)
- [Report Issues](https://github.com/smartwatermelon/code-critic-plugin/issues)
