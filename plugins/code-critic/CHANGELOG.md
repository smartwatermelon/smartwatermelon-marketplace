# Changelog

## v1.3.0

- **"Lead with verdict" resolved**: Automated pipelines state
  verdict in Summary line; interactive reviews keep verdict at end
- **Sections consolidated**: Review Context Awareness merged into
  Context and Scope
- **Hook over-trigger guard**: Insufficient Context verdict reserved
  for interactive reviews; automated pipelines use partial
  assessment
- **Skip-critic clarified**: Application-level skips distinguished
  from git-level bypass; skip logging added to examples
- **Pre-commit hook fix**: Dead code from `set -e` + `$?` replaced
  with proper exit code capture
- **USAGE.md Example 2**: Alternative Approaches section added for
  presigned URL pattern
- **Changelogs extracted**: Version history moved to this file

## v1.2.0

- **Observability checklist**: New failure mode category — can you
  tell when this is broken in production?
- **Insufficient Context verdict**: Fourth verdict option for partial
  reviews where context is missing
- **Diff-awareness**: Guidance for adapting review depth to diffs vs.
  full files vs. snippets
- **Output length calibration**: Concise for git hooks, thorough for
  interactive review
- **Confidence signaling**: Distinguishes confirmed findings from
  pattern-based suspicions
- **Domain Awareness repositioned**: Now sets the review lens before
  the hierarchy is applied
- **Configuration/prompts/IaC domain**: New domain-specific guidance
  for reviewing config and prompt files
- **Honest calibration restored**: "Genuinely good code is rare"
  qualifier reinstated
- **Documentation fixes**: Examples updated to match defined response
  format, severity/verdict duplication removed, `--no-verify`
  references replaced with safe alternatives

## v1.1.0

- **Failure mode checklist**: Systematic review across concurrency,
  resource management, distributed systems, error handling, security,
  and data integrity — not just general skepticism
- **Data model review**: Schema design elevated to second priority in
  the review hierarchy
- **Severity calibration**: Clear definitions for Critical (blocks
  merge), Concern (should fix), and Question (needs justification)
- **Verdict**: Every review ends with a clear disposition — Block,
  Revise, or Accept
- **Follow-up protocol**: Guidance for iterative review, handling
  pushback, and updating assessments
- **Domain awareness**: Adjusts review lens for backend, frontend,
  data pipelines, APIs, and tests
- **Context and scope**: Explicit instructions to read surrounding
  code and trace data flow before forming opinions
- **Honest calibration**: Good code gets recognized with the same
  rigor as bad code — no manufactured criticism
- **Activation Criteria removed**: Usage guidance now lives in README
  and USAGE.md, not in the agent prompt

## v1.0.0

- Initial release: adversarial code review agent with review
  hierarchy, behavioral rules, and response format
