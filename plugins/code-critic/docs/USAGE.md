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
6. Provide specific, actionable feedback with a clear verdict (Block, Revise, or Accept)

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
"JWT refresh implementation review:

PURPOSE:
- Why auto-refresh 5 minutes before expiration? That's arbitrary. Have you measured your 95th percentile request duration? If requests can take 30 seconds, this window is too tight.
- What problem does refresh solve vs. making the access token longer-lived? Refresh tokens introduce state and complexity.

ARCHITECTURE:
- Storing refresh token in HTTP-only cookie: Good. But where's the CSRF protection? Cookie alone isn't enough.
- Token refresh happens client-side. What happens when multiple tabs try to refresh simultaneously? Race condition.

FAILURE MODES:
- Refresh token rotation not atomic. If the database write succeeds but the response fails, user is locked out. Where's the rollback?
- No exponential backoff on refresh failures. Client will hammer your refresh endpoint during outages.
- What happens if refresh takes longer than the access token's remaining lifetime? User sees auth failures.

RECOMMENDATIONS:
1. Add mutex/lock for per-user refresh operations
2. Implement sliding refresh window instead of hard cutoff
3. Add circuit breaker for refresh endpoint
4. Store refresh attempt count to detect compromise
5. Add integration test for concurrent refresh attempts

VERDICT: Block. The race condition on concurrent refresh and the non-atomic
token rotation will cause user lockouts in production. Fix those two before
merging."
```

### Example 2: Reviewing an API Design

```
User: I've designed this new API endpoint for file uploads

Claude: [Uses adversarial-reviewer agent]

Agent Response:
"API design review:

PURPOSE:
- You're accepting arbitrary file sizes. Have you considered the cost implications? A 5GB upload to S3 costs you money even if it fails validation.
- Why synchronous upload? This blocks your API workers. Should be async with job queue.

ARCHITECTURE:
- File goes through your API server to S3. Why? This adds latency and costs. Client should upload directly to S3 with presigned URLs.
- No mention of virus scanning. Every file upload endpoint needs malware detection.

FAILURE MODES:
- Upload fails at 90%—where's the resume capability? User starts over?
- Multiple concurrent uploads from same user—where's the rate limiting?
- File metadata stored separate from file in S3. These will get out of sync. How do you reconcile?

IMPLEMENTATION:
- Multipart upload chunks are 5MB. Fine for most files, but configurable? 100MB file = 20 requests = 20 chances to fail.

RECOMMENDATIONS:
1. Use S3 presigned URLs for direct uploads
2. Implement resumable uploads (tus protocol or similar)
3. Add virus scanning (ClamAV or AWS GuardDuty)
4. Store all metadata as S3 object tags for consistency
5. Add per-user upload rate limiting
6. Consider S3 Transfer Acceleration for global users

VERDICT: Revise. The direct-to-S3 upload is an architecture change, not a
tweak — rework the upload path, add virus scanning, and I'd approve."
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

### Severity Calibration

The agent applies these standards consistently:

- **Critical** (blocks merge): The code will break in production under realistic conditions. Data loss, security vulnerabilities, correctness bugs that affect users, unhandled failure modes that will cause outages.
- **Concern** (should fix, doesn't block): Technical debt that will compound. Missing observability. Coupling that will make the next change painful. Performance issues that don't matter now but will at 10x scale.
- **Question** (needs justification): Design decisions that seem undermotivated. Trade-offs that weren't explained. Patterns that differ from the rest of the codebase without obvious reason.

### Verdict

Every review ends with a clear disposition:

- **Block**: "Do not merge this. [These issues] must be addressed first."
- **Revise**: "This needs changes before merging: [specific list]. I'd approve once those are addressed."
- **Accept**: "This is solid. [Brief explanation of why.] Ship it."

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
