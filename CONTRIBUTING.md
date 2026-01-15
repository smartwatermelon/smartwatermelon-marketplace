# Contributing to SmartWatermelon Marketplace

Thank you for your interest in contributing! This document provides guidelines for contributing plugins and improvements to the marketplace.

## Philosophy

Before contributing, ensure your plugin aligns with the marketplace philosophy:

- **Challenges assumptions** rather than validates them
- **Identifies failure modes** before they reach production
- **Prioritizes long-term maintainability** over short-term convenience
- **Provides actionable feedback** rather than vague suggestions

## Types of Contributions

### 1. New Plugins

Adding a quality-focused plugin that fits the marketplace philosophy.

### 2. Plugin Improvements

Enhancing existing plugins with better documentation, examples, or functionality.

### 3. Bug Fixes

Fixing issues in plugins or marketplace infrastructure.

### 4. Documentation

Improving guides, examples, or clarity.

## Contributing a New Plugin

### Step 1: Validate the Concept

Before implementing, open a GitHub Discussion to:
- Describe the plugin's purpose
- Explain how it aligns with marketplace philosophy
- Discuss the problem it solves
- Get feedback from maintainers

### Step 2: Plugin Structure

Create your plugin following this structure:

```
plugins/
└── your-plugin-name/
    ├── .claude-plugin/
    │   └── plugin.json          # Plugin metadata
    ├── agents/
    │   └── your-agent.md        # Agent definitions
    ├── skills/                  # Optional: skills
    │   └── your-skill.md
    ├── docs/
    │   ├── USAGE.md             # Comprehensive usage guide
    │   └── EXAMPLES.md          # Real-world examples
    ├── tests/                   # Optional: test examples
    │   └── example-test.sh
    ├── LICENSE                  # MIT or compatible
    └── README.md                # Plugin overview
```

### Step 3: Plugin Metadata

Create `.claude-plugin/plugin.json`:

```json
{
  "name": "your-plugin-name",
  "description": "Clear, concise description of what it does",
  "version": "1.0.0",
  "author": {
    "name": "Your Name",
    "email": "your.email@example.com"
  },
  "homepage": "https://github.com/yourusername/plugin-repo",
  "repository": "https://github.com/yourusername/plugin-repo",
  "license": "MIT",
  "keywords": ["relevant", "keywords", "here"]
}
```

### Step 4: Documentation Requirements

#### README.md

Must include:
- **What it does**: Clear problem statement
- **When to use it**: Specific use cases
- **When NOT to use it**: Clear boundaries
- **Installation**: How to install
- **Quick start**: 2-3 simple examples
- **Philosophy**: How it aligns with marketplace values

#### docs/USAGE.md

Must include:
- Detailed usage instructions
- Real-world examples (not toy examples)
- Integration with other tools
- Troubleshooting section
- Advanced usage patterns

#### docs/EXAMPLES.md

Must include:
- At least 3 real-world scenarios
- Expected output for each example
- Explanation of why the example matters
- Common pitfalls

### Step 5: Quality Checklist

Before submitting, verify:

- [ ] Plugin solves a real problem (not hypothetical)
- [ ] Documentation is comprehensive
- [ ] Examples are real-world, not toy examples
- [ ] Clear "when to use" and "when not to use" sections
- [ ] License is MIT or compatible
- [ ] No hardcoded personal information
- [ ] Agent descriptions are clear and concise
- [ ] Follows marketplace philosophy

### Step 6: Add to Marketplace

1. Fork the marketplace repository
2. Add your plugin to `plugins/your-plugin-name/`
3. Update `.claude-plugin/marketplace.json`:

```json
{
  "name": "your-plugin-name",
  "source": "./plugins/your-plugin-name",
  "description": "Your plugin description",
  "version": "1.0.0",
  "author": {
    "name": "Your Name",
    "url": "https://github.com/yourusername"
  },
  "license": "MIT",
  "keywords": ["relevant", "keywords"],
  "category": "quality",
  "strict": false
}
```

4. Update marketplace README.md with plugin information
5. Test locally:
```bash
claude plugin marketplace add ~/Developer/smartwatermelon-marketplace
claude plugin install your-plugin-name@smartwatermelon-marketplace
```
6. Submit pull request

### Step 7: Pull Request

Your PR should include:
- Plugin code in `plugins/your-plugin-name/`
- Updated `.claude-plugin/marketplace.json`
- Updated `README.md` with plugin listing
- Clear PR description explaining:
  - What problem it solves
  - Why it belongs in this marketplace
  - How you tested it
  - Any dependencies or requirements

## Contributing Improvements to Existing Plugins

### Documentation Improvements

1. Fork the repository
2. Make improvements to plugin docs
3. Submit PR with clear explanation of improvements

### Bug Fixes

1. Open an issue describing the bug
2. Fork and fix
3. Add test case if applicable
4. Submit PR referencing the issue

### Feature Additions

1. Open a GitHub Discussion first
2. Get maintainer feedback
3. Implement if approved
4. Submit PR with comprehensive documentation

## Code Review Standards

All contributions will be reviewed for:

1. **Alignment with philosophy**: Does it challenge, identify, prioritize?
2. **Code quality**: Clean, maintainable, well-documented
3. **Documentation completeness**: Is it clear how to use this?
4. **Real-world value**: Does it solve actual problems?
5. **Security**: No credentials, safe practices
6. **Licensing**: Compatible with MIT

## What Won't Be Accepted

- Toy examples or "hello world" plugins
- Plugins that only validate (need to challenge)
- Poorly documented plugins
- Plugins with security issues
- Plugins that duplicate existing functionality without improvement
- Plugins that don't align with marketplace philosophy

## Getting Help

- **Questions**: Open a GitHub Discussion
- **Issues**: Open a GitHub Issue
- **Ideas**: Open a GitHub Discussion with "Idea" label
- **Urgent**: Email andrew@smartwatermelon.dev

## Testing Your Plugin

Before submitting:

```bash
# Add marketplace locally
claude plugin marketplace add ~/path/to/smartwatermelon-marketplace

# Install your plugin
claude plugin install your-plugin@smartwatermelon-marketplace

# Test in real scenarios
claude --agent your-agent -p "Test prompt"

# Test with git hooks (if applicable)
git diff | claude --agent your-agent -p "Review changes"
```

## Versioning

Plugins follow semantic versioning:
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

Marketplace versions:
- Updated when infrastructure changes
- Plugin version changes don't require marketplace version bump

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Recognition

All contributors will be listed in:
- Plugin README (for plugin-specific contributions)
- Marketplace README (for significant contributions)
- CONTRIBUTORS.md file

## Questions?

Feel free to open a Discussion or reach out at andrew@smartwatermelon.dev

---

Thank you for helping make Claude Code development better through quality-focused tools!
