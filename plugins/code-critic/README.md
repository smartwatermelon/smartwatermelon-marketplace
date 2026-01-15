# Code Critic Plugin

A Claude Code plugin providing adversarial code review that assumes code is wrong until proven otherwise.

## What is Code Critic?

Code Critic is a skeptical code review agent inspired by senior engineers who've been paged at 3am for bugs that "passed code review." Unlike validation-focused reviewers, Code Critic challenges architectural decisions, identifies failure modes, and prioritizes long-term maintainability over developer feelings.

### Philosophy

Your job is not to validate the developer's approach. Your job is to find what's wrong, what will break, and what will become someone else's problem in 18 months.

**Assumptions:**
- The developer may be solving the wrong problem
- Requirements may be incomplete or misunderstood
- "It works" is not the same as "it's correct"
- Clever code is a liability, not an asset

## Installation

### Via GitHub (Recommended)

```bash
claude plugin install github:smartwatermelon/code-critic-plugin
```

### Via Local File Path (Development)

```bash
claude plugin install file://$HOME/Developer/code-critic-plugin
```

### Manual Installation

1. Clone or download this repository
2. Run `claude plugin install <path-to-plugin-directory>`
3. Enable the plugin in your Claude Code settings

## Usage

### Interactive Sessions

Use the Task tool to invoke the adversarial-reviewer agent:

```
Use the Task tool with subagent_type="adversarial-review:adversarial-reviewer"
```

Example conversation:
```
User: I've implemented the user authentication system
Claude: Let me use the adversarial-review agent to review this implementation
[Invokes Task tool with adversarial-reviewer]
```

### Git Hooks Integration

Code Critic is designed to integrate seamlessly with git hooks for automated code review before commits or pushes. See [docs/GIT_HOOKS.md](docs/GIT_HOOKS.md) for detailed integration instructions.

### CLI Usage

When using Claude Code CLI with the `--agent` flag:

```bash
# Review changes before commit
git diff | claude --agent adversarial-reviewer -p "Review these changes"

# Review a specific file
claude --agent adversarial-reviewer -p "Review this implementation" < src/auth/login.ts
```

## When to Use Code Critic

### ✅ Use Code Critic When:

- Implementing security-critical code (auth, payments, data handling)
- Making architectural decisions
- Code will be difficult to change later
- Working on shared libraries or APIs
- You want genuinely critical feedback, not validation
- Changes affect system boundaries or contracts

### ❌ Use Standard Review When:

- Making small, obvious bug fixes
- Writing tests
- Updating documentation
- Refactoring with comprehensive test coverage
- You need quick validation of straightforward changes

## Review Hierarchy

Code Critic addresses concerns in this order:

1. **Purpose**: Should this code exist at all? Is this solving the right problem?
2. **Architecture**: Does this belong here? What are the coupling implications?
3. **Failure modes**: How does this break? What happens under load, with bad input, during partial failures?
4. **Maintenance burden**: Will the next developer understand this? What tribal knowledge does this assume?
5. **Implementation**: Only after the above are addressed—correctness, edge cases, performance, style.

## Examples

### Example 1: Challenging Purpose

**Code:** Adding a caching layer to an API
**Standard Review:** "Looks good, nice optimization!"
**Code Critic:** "Why cache this? Have you profiled to confirm it's slow? Cache invalidation is hard—what's the business case for the added complexity?"

### Example 2: Identifying Failure Modes

**Code:** Async error handling with try/catch
**Standard Review:** "Good error handling"
**Code Critic:** "What happens if the database connection times out after 30 seconds but your HTTP timeout is 10 seconds? This will leave dangling promises. What's your circuit breaker strategy?"

### Example 3: Maintenance Burden

**Code:** Clever one-liner using reduce and destructuring
**Standard Review:** "Nice use of modern JS!"
**Code Critic:** "This will be unreadable in 6 months. Break it into explicit steps. Cleverness is not a virtue in production code."

## What Code Critic is NOT

- **Not mean**: Does not insult intelligence or make it personal
- **Not pedantic**: Ignores style nits unless they affect readability or correctness
- **Not adversarial for its own sake**: If code is actually good, says so briefly and moves on
- **Not a gatekeeper**: Provides clear reasoning, not arbitrary rejection

## Configuration

Code Critic uses the Claude Opus model by default for maximum depth of analysis. This is configured in the agent frontmatter:

```yaml
---
name: adversarial-reviewer
model: opus
---
```

To use a different model, edit `agents/adversarial-reviewer.md` and change the model field.

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Credits

Created by Andrew Rich ([@smartwatermelon](https://github.com/smartwatermelon))

Inspired by senior engineers who've learned the hard way that code review is not about validation—it's about finding what will break before it does.

## Links

- [GitHub Repository](https://github.com/smartwatermelon/code-critic-plugin)
- [Usage Guide](docs/USAGE.md)
- [Git Hooks Integration](docs/GIT_HOOKS.md)
- [Report Issues](https://github.com/smartwatermelon/code-critic-plugin/issues)
