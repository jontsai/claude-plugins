# Review PR Plugin

Generate guided PR review tours that walk through code changes in logical order.

## Features

- **Logical file ordering** - Depth-first traversal matching GitHub UI
- **Tour stops** - Digestible review points (~25 lines max per stop)
- **Context-rich** - Explains why code exists and its history
- **Review priorities** - Highlights what needs rigorous review vs. rubber-stamp
- **Smart mode detection** - Adapts behavior for CLI vs pass-through (OpenClaw) contexts
- **Confidence-based posting** - Posts directly when confident, discusses first when not
- **Approval workflow** - Review and approve PRs with semantic approval messages
- **Issue tracker integration** - Compare implementation against requirements (GitHub Issues, Jira, Linear, etc.)

## Installation

```bash
/plugin marketplace add jontsai/claude-plugins
/plugin install review-pr@jontsai
```

## Usage

Simply ask Claude to review a PR:

```
review PR #123
walk me through this PR
review https://github.com/owner/repo/pull/456
review and approve PR #789
```

### Operation Modes

The plugin automatically detects the operation context:

| Context | Default Behavior |
|---------|-----------------|
| Claude Code CLI (interactive) | Display review locally first, then offer to post |
| Pass-through tool (OpenClaw, etc.) | Post inline comments directly (if confident) |

### Confidence-Based Workflow

- **High confidence**: Posts comments directly in pass-through mode
- **Low confidence**: Always discusses locally first before posting

### Review Modes

1. **CLI Display** - Shows tour guide in terminal (default for interactive CLI)
2. **Inline PR Comments** - Posts comments directly on PR (default for pass-through when confident)
3. **Tour Guide Mode** - Posts reviewer notes to guide human reviewers

### Conventional Comment Labels

When posting inline comments, the skill uses standard labels:

| Label | Use Case |
|-------|----------|
| `suggestion:` | Improvements, refactoring ideas |
| `thought:` | Considerations, questions for discussion |
| `nit:` | Minor style/formatting issues |
| `question:` | Clarification needed |
| `praise:` | Good patterns worth noting |
| `issue:` | Bugs or problems found |

### Approval Workflow

When asked to "review and approve", the plugin:

1. Completes a full review
2. Assesses for red flags and risks
3. Presents findings with confidence assessment
4. Asks for user's confidence level before approving
5. Approves with appropriate semantic message

**Never auto-approves** - always requires user confirmation.

### Semantic Approval Messages

| Message | Meaning |
|---------|---------|
| **LGTM** | Looks Good To Me - High confidence, would approve without hesitation |
| **lgtm** | looks good to me - Lower confidence, quieter approval |
| **LFTM** | Looks Fine To Me - High confidence it won't break, pragmatic approval |
| **lftm** | looks fine to me - Lower confidence, recommend user has fully tested |

## Requirements

- `gh` CLI installed and authenticated
- Repository access for the PR being reviewed

## License

MIT
