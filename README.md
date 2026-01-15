# SmartWatermelon Marketplace

A curated collection of quality-focused plugins for Claude Code, emphasizing critical code review, testing tools, and development workflows.

## Philosophy

This marketplace focuses on plugins that:
- **Challenge assumptions** rather than validate them
- **Identify failure modes** before they reach production
- **Prioritize long-term maintainability** over short-term convenience
- **Provide actionable feedback** rather than vague suggestions

## Installation

Add this marketplace to your Claude Code installation:

```bash
claude plugin marketplace add github:smartwatermelon/smartwatermelon-marketplace
```

After adding the marketplace, you can install individual plugins:

```bash
# Install specific plugin
claude plugin install code-critic@smartwatermelon-marketplace

# Or install all plugins
claude plugin install --all smartwatermelon-marketplace
```

## Available Plugins

### Code Critic

**Status**: Stable v1.0.0
**Category**: Quality / Code Review

Skeptical code review agent that assumes code is wrong until proven otherwise. Unlike validation-focused reviewers, Code Critic challenges architectural decisions, identifies failure modes, and prioritizes long-term maintainability.

**Features**:
- Reviews code hierarchy: Purpose → Architecture → Failure Modes → Maintenance → Implementation
- Challenges assumptions and asks "why" before "how"
- Identifies race conditions, error handling gaps, and scalability issues
- Integrates with git hooks for automated review

**When to use**:
- Security-critical code (auth, payments, data handling)
- Architectural changes
- Complex business logic
- High-risk refactoring

**Documentation**: [plugins/code-critic/README.md](plugins/code-critic/README.md)

**Install**:
```bash
claude plugin install code-critic@smartwatermelon-marketplace
```

---

## Coming Soon

More plugins are in development:

- **test-driven-discipline**: TDD workflow enforcement and test quality analysis
- **performance-guardian**: Performance regression detection and optimization suggestions
- **api-contract-validator**: API contract testing and breaking change detection
- **documentation-critic**: Documentation completeness and clarity analysis

## Plugin Development

Want to contribute a plugin to this marketplace? See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Adding a New Plugin

1. Create plugin in `plugins/<plugin-name>/`
2. Add plugin metadata to `.claude-plugin/marketplace.json`
3. Update this README with plugin information
4. Submit a pull request

### Plugin Structure

```
plugins/
└── your-plugin/
    ├── .claude-plugin/
    │   └── plugin.json
    ├── agents/
    │   └── your-agent.md
    ├── docs/
    │   ├── USAGE.md
    │   └── [other docs]
    ├── LICENSE
    └── README.md
```

### Quality Standards

Plugins in this marketplace must:
- Have comprehensive documentation
- Include usage examples
- Specify clear use cases (when to use, when not to use)
- Follow the marketplace philosophy (challenge, identify, prioritize)
- Include MIT or compatible license
- Pass local testing before submission

## Marketplace Philosophy

### Why "SmartWatermelon"?

SmartWatermelon represents the intersection of:
- **Smart**: Intelligent, thoughtful tooling that enhances developer capabilities
- **Watermelon**: Fresh perspective, cutting through to the core of problems

### Quality Over Quantity

This marketplace emphasizes quality over quantity. Each plugin is:
- **Purpose-driven**: Solves a specific, real problem
- **Well-documented**: Clear usage guide with examples
- **Battle-tested**: Used in real projects
- **Maintainable**: Clean code, clear architecture

### Not Just Another Marketplace

Unlike general-purpose marketplaces, SmartWatermelon focuses on:
1. **Critical thinking tools** - Plugins that challenge and improve your thinking
2. **Quality assurance** - Tools that catch problems before they ship
3. **Developer discipline** - Workflows that enforce best practices

## Support

- **Issues**: [GitHub Issues](https://github.com/smartwatermelon/smartwatermelon-marketplace/issues)
- **Discussions**: [GitHub Discussions](https://github.com/smartwatermelon/smartwatermelon-marketplace/discussions)
- **Contact**: andrew@smartwatermelon.dev

## License

Marketplace infrastructure: MIT License

Individual plugins: See plugin LICENSE files

## Credits

Created and maintained by Andrew Rich ([@smartwatermelon](https://github.com/smartwatermelon))

Inspired by the philosophy that good tools challenge us to be better developers.

---

**Latest Version**: 1.0.0
**Last Updated**: 2026-01-15
