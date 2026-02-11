# Code Critic Usage Guide

This guide provides detailed examples and workflows for using the Code Critic plugin effectively.

## Table of Contents

- [Basic Usage](#basic-usage)
- [Interactive Sessions](#interactive-sessions)
- [CLI Usage](#cli-usage)
- [Git Hooks Integration](#git-hooks-integration)
- [Review Workflow](#review-workflow)
- [Advanced Usage](#advanced-usage)

## Basic Usage

### In Interactive Claude Code Sessions

When working in an interactive Claude Code session, you can invoke the adversarial-reviewer agent using the Task tool:

```
User: I've finished implementing the authentication middleware
Claude: Let me review this implementation using the adversarial-reviewer agent
[Uses Task tool with subagent_type="adversarial-review:adversarial-reviewer"]
```

The agent will:

1. Analyze your code from a skeptical perspective
2. Check the data model for invalid-state representation
3. Challenge architectural decisions
4. Systematically check for failure modes (concurrency, resource leaks, distributed systems, security, data integrity)
5. Question maintenance burden
6. Provide specific, actionable feedback with a clear verdict (Block, Revise, Accept, or Insufficient Context)

### Agent Naming

The plugin provides a single agent:

- **Plugin name**: `code-critic`
- **Agent name**: `adversarial-reviewer`
- **Full reference**: `code-critic:adversarial-reviewer`

## Interactive Sessions

### Example 1: After Implementing a Feature

```
User: I've finished implementing JWT token refresh in src/auth/jwt-refresh.ts

Claude: Let me use the adversarial-reviewer agent to thoroughly review this security-critical implementation
[Invokes Task tool]

Agent Response:
"### Summary
JWT refresh implementation that auto-refreshes 5 minutes before
expiration. Primary concern: race conditions on concurrent refresh
and non-atomic token rotation will cause user lockouts.

### Critical Issues
- **Non-atomic token rotation**: If the database write succeeds but
  the response fails, the old refresh token is invalidated and the
  client never receives the new one. User is locked out with no
  recovery path.
- **Concurrent refresh race condition**: Multiple browser tabs can
  trigger refresh simultaneously. Without a per-user mutex, both
  tabs invalidate each other's tokens. This is a guaranteed
  production issue for any user with multiple tabs.

### Concerns
- No exponential backoff on refresh failures. During an auth service
  outage, every client retries immediately — retry storm.
- The 5-minute refresh window is arbitrary. If your 95th percentile
  request duration approaches 5 minutes, users will see auth
  failures during long operations.

### Questions
- Why auto-refresh instead of longer-lived access tokens? The refresh
  token introduces state management complexity. What's the threat
  model that justifies it?
- Where's the CSRF protection? HTTP-only cookie alone isn't enough.

### Verdict
**Block.** The race condition on concurrent refresh and the
non-atomic token rotation will cause user lockouts in production.
Fix those two before merging."
```

### Example 2: Reviewing an API Design

```
User: I've designed this new API endpoint for file uploads

Claude: [Uses adversarial-reviewer agent]

Agent Response:
"### Summary
File upload API that proxies through the API server to S3. Primary
concern: the architecture is fundamentally wrong — proxying uploads
through your server adds cost, latency, and failure modes that
presigned URLs would eliminate.

### Critical Issues
- **No virus scanning**: Every file upload endpoint needs malware
  detection. Accepting arbitrary files from users without scanning
  is a security gap. ClamAV or AWS GuardDuty before the file
  reaches your storage layer.

### Concerns
- No resume capability. A 90%-complete upload that fails means the
  user starts over. Consider the tus protocol for resumable uploads.
- File metadata stored separately from files in S3. These will
  drift. S3 object tags would keep them co-located.
- No per-user upload rate limiting. A single user can consume all
  your upload bandwidth.

### Alternative Approaches
- **Direct-to-S3 presigned URLs**: Instead of proxying uploads
  through your API server, generate a presigned URL and let the
  client upload directly to S3. This eliminates server-side
  bandwidth cost, reduces latency, and removes your API server
  as a failure point in the upload path. Your API only handles
  the lightweight presign request and post-upload metadata.

### Questions
- Why synchronous upload? This blocks API workers. What's the
  expected file size distribution? Anything over 10MB should be
  async with a job queue.
- Why accept arbitrary file sizes? A 5GB upload costs you money
  even if it fails validation. What's the max you actually need?

### Verdict
**Revise.** The direct-to-S3 upload is an architecture change, not
a tweak — rework the upload path, add virus scanning, and I'd
approve."
```

## CLI Usage

### Review Uncommitted Changes

```bash
# Review all staged changes
git diff --cached | claude --agent adversarial-reviewer -p "Review these staged changes"

# Review specific file
git diff src/payment/processor.ts | claude --agent adversarial-reviewer -p "Review this payment processing code"

# Review branch changes
git diff main...feature-branch | claude --agent adversarial-reviewer -p "Review changes in this branch"
```

### Review Specific Files

```bash
# Review a single file
claude --agent adversarial-reviewer -p "Review this implementation" < src/auth/middleware.ts

# Review multiple files
cat src/api/*.ts | claude --agent adversarial-reviewer -p "Review these API handlers"
```

### Pipe from Other Tools

```bash
# Review eslint violations
eslint src/ --format=json | claude --agent adversarial-reviewer -p "Analyze these lint violations and identify architectural issues"

# Review test failures
npm test 2>&1 | claude --agent adversarial-reviewer -p "Analyze these test failures for potential architectural problems"
```

## Git Hooks Integration

See [GIT_HOOKS.md](GIT_HOOKS.md) for comprehensive git hooks integration guide.

### Quick Setup

Add to `.git/hooks/pre-push`:

```bash
#!/bin/bash
set -e

# Get files changed in this push
FILES=$(git diff --name-only origin/main...HEAD -- '*.ts' '*.js')

if [ -z "$FILES" ]; then
  echo "No code files to review"
  exit 0
fi

echo "Running adversarial code review..."
git diff origin/main...HEAD | claude --agent adversarial-reviewer -p "Review these changes before push" --no-session-persistence -p

if [ $? -ne 0 ]; then
  echo "❌ Adversarial review found critical issues"
  exit 1
fi
```

## Review Workflow

### When to Use Code Critic

#### ✅ High-Value Scenarios

1. **Security-Critical Code**
   - Authentication/authorization
   - Payment processing
   - Data access controls
   - Cryptographic operations

2. **Architectural Changes**
   - New service boundaries
   - Database schema changes
   - API contract changes
   - Shared library modifications

3. **Complex Business Logic**
   - State machines
   - Multi-step workflows
   - Transaction handling
   - Data consistency requirements

4. **High-Risk Refactoring**
   - Changing core abstractions
   - Performance-critical code
   - Backward compatibility concerns

#### ❌ Low-Value Scenarios

1. **Obvious Bug Fixes**
   - Typo corrections
   - Off-by-one errors
   - Missing null checks (when obvious)

2. **Test Code** (Usually)
   - Unit tests
   - Integration tests
   - Unless tests reveal architectural issues

3. **Documentation Updates**
   - README changes
   - Comment updates
   - API documentation

### Review Cadence

**Project Type** | **Recommended Frequency**
-----------------|---------------------------
New greenfield project | Every commit
Mature, stable codebase | Before merge to main
Security-critical features | Every code change
Experimental/prototype | Before productionizing
Legacy refactoring | After each logical chunk

## Advanced Usage

### Custom Review Focus

You can ask the agent to focus on specific concerns:

```bash
# Focus on security
git diff | claude --agent adversarial-reviewer -p "Review security implications of these changes"

# Focus on performance
git diff | claude --agent adversarial-reviewer -p "Review performance and scalability of this implementation"

# Focus on maintainability
git diff | claude --agent adversarial-reviewer -p "Review long-term maintenance burden of this code"
```

### Combining with Other Reviews

Code Critic complements, not replaces, other review methods:

1. **Automated linting** → Catches style issues
2. **Type checking** → Catches type errors
3. **Unit tests** → Validates correctness
4. **Standard code review** → Validates requirements
5. **Code Critic** → Challenges assumptions, identifies failure modes

### Integration with Claude Code Workflows

Code Critic works well with Claude Code's built-in workflow plugins:

- Use after `tdd-workflows` to validate your TDD implementation approach
- Use before `git-pr-workflows` to catch issues before PR creation
- Use alongside `comprehensive-review` for security-critical code

## Tips for Effective Use

### 1. Provide Context

Give the agent context about your system:

```
User: Review this cache implementation. Context: We have 10k requests/second,
cache hit rate needs to be >90%, and we can't afford cache stampede during
invalidation
```

### 2. Be Specific About Concerns

```
User: Review this API rate limiter. I'm particularly concerned about:
- Distributed rate limiting across multiple API servers
- Edge cases during server restarts
- Handling clock skew between servers
```

### 3. Iterate on Feedback

```
User: Here's the updated implementation addressing the race condition you
identified. Does this resolve your concerns?
```

### 4. Use for Learning

Even if you disagree with feedback, understand the reasoning:

```
User: You suggested avoiding clever code, but this one-liner is idiomatic in
our codebase and all devs understand it. Can you explain the maintenance
concern?
```

## Interpreting Feedback

### Severity and Verdict

The agent uses three severity levels (Critical, Concern, Question) and four verdicts (Block, Revise, Accept, Insufficient Context). See the [agent prompt](../agents/adversarial-reviewer.md) for full definitions — it is the source of truth for these standards.

### When to Push Back

Code Critic is opinionated. Push back when:

1. **Team conventions differ**: "Our team prefers X pattern"
2. **Context wasn't provided**: "This handles Y which wasn't mentioned"
3. **Trade-offs are acceptable**: "We accept this complexity for Z benefit"
4. **Requirements differ**: "Actually, the requirement is..."

The goal is thoughtful discussion, not blind acceptance.

## Troubleshooting

### Agent Not Available

```bash
# Verify plugin is installed
claude plugin list

# Verify plugin is enabled
cat ~/.claude/settings.json | jq '.enabledPlugins'

# Reinstall if needed
claude plugin install github:smartwatermelon/code-critic-plugin
```

### Reviews Too Harsh / Too Lenient

The agent's model (Opus) provides deep analysis. If you need faster, lighter reviews:

1. Edit `agents/adversarial-reviewer.md`
2. Change `model: opus` to `model: sonnet`
3. Reinstall plugin

### Feedback Not Actionable

Provide more context in your prompt:

```
Bad:  "Review this code"
Good: "Review this payment processing code. Focus on race conditions and
      failure modes during high load."
```

## Examples of Great Feedback

### Example: Identifying Missing Error Handling

```
"Your async/await chain has no error boundaries. If the database query fails,
the promise will reject and crash the process. Add try/catch around all async
operations, or use a global error handler. Consider: what happens when the DB
is slow? Does this timeout? Where?"
```

### Example: Challenging Assumptions

```
"You're caching user permissions in Redis with 5-minute TTL. Why 5 minutes?
If permissions change, users have stale auth for up to 5 minutes. If that's
acceptable, document it. If not, implement cache invalidation on permission
changes. Also: what's your cache-miss strategy? If Redis is down, do all
requests fail?"
```

### Example: Suggesting Better Approach

```
"You're implementing your own UUID generation. Why? Use a well-tested library
(uuid npm package). Rolling your own risks collisions, which could corrupt
your database. Unless you have specific requirements the standard library
doesn't meet (which you haven't mentioned), use the standard."
```

## Further Reading

- [Git Hooks Integration Guide](GIT_HOOKS.md)
- [Plugin README](../README.md)
- [Report Issues](https://github.com/smartwatermelon/code-critic-plugin/issues)
