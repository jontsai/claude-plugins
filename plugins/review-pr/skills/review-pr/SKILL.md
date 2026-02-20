---
name: review-pr
description: |
  Generate a guided PR review tour that walks through code changes in logical order.
  Creates a "street guide" with landmarks, context, and review priorities.
  Triggers: "review PR #123", "walk me through this PR", "PR tour guide", "explain this PR", "review and approve".
  Supports CLI display, PR comments, and human-style inline reviews. Can approve PRs with semantic messages.
---

# PR Review Tour Guide

Generate a structured, guided tour of a Pull Request that helps reviewers understand changes efficiently. Acts as a knowledgeable guide walking someone through a codebase change.

## Automatic Invocation Triggers

Claude will invoke this skill when you:
- Ask to "review PR #123" or "review this PR"
- Say "walk me through this PR"
- Request "PR tour guide" or "explain this PR"
- Ask "what should I look for in this PR"
- Say "create a PR review walkthrough"
- Request "review and approve PR #123" (triggers review with approval workflow)

## Overview

This skill creates a guided tour of PR changes that:
- **Orders files logically** (as GitHub UI shows - depth-first with folders before files)
- **Groups review points** into digestible stops (no more than ~25 lines per stop)
- **Provides context** about why code exists and its history
- **Highlights review priorities** (what needs rigorous review vs. rubber-stamp)
- **Uses landmarks** (line numbers, class/function names) for easy navigation

## Input Requirements

The skill needs:
1. **PR number** and **repository** (e.g., "PR #3091 in altimate-backend")
2. OR a **PR URL** (e.g., "https://github.com/owner/repo/pull/3091")
3. Optionally, a **linked issue/ticket** for context comparison (GitHub Issues, Jira, Linear, etc.)

## Operation Mode Detection

Before starting the review, detect the operation context to determine default behavior:

### Detecting Operation Mode

**CLI Mode Indicators** (weight toward local display first):
- Running in Claude Code CLI directly
- User is interactively typing commands
- Terminal/TTY is available
- No delegation context detected

**Pass-Through/Delegated Mode Indicators** (weight toward inline GitHub comments):
- Request came via OpenClaw or similar delegation tool
- Request came from automation/CI context
- Request mentions "post comments" or "leave feedback on PR"
- No interactive terminal available

### Default Behavior by Mode

| Mode | Default Action | Rationale |
|------|---------------|-----------|
| CLI (interactive) | Display review locally first, then offer to post | User can review and edit before posting |
| Pass-through/Delegated | Post inline comments directly (if confident) | Automation context benefits from persistent comments |

**If unsure about mode:** Ask the user: "Would you like me to display the review here first, or post comments directly on the PR?"

## Workflow

### Step 1: Gather PR Information

```bash
# Get PR metadata
gh pr view <PR_NUMBER> --repo <OWNER/REPO> --json title,body,additions,deletions,changedFiles,files,commits

# Get the full diff
gh pr diff <PR_NUMBER> --repo <OWNER/REPO>

# If linked issue/ticket provided, fetch details based on tracker type:
# - GitHub Issues: gh issue view <ISSUE_NUMBER> --repo <OWNER/REPO>
# - Jira: Use mcp__atlassian__getJiraIssue or API
# - Linear: Use Linear MCP or API
# - Other trackers: Use appropriate MCP or API
```

### Step 2: Analyze and Order Files

Order files using depth-first traversal (folders before files):
1. At each directory level, process subdirectories first (alphabetically), recursively
2. Then process files in the current directory (alphabetically)
3. This ensures reviewers see related nested changes together before sibling files

**Example ordering:**
```
app/
  models/
    user.py          # 1. Deepest nested first
    account.py       # 2. Same level, alphabetical
  services/
    auth.py          # 3. Next subdirectory
  utils.py           # 4. Files in app/ after all subdirectories
config/
  settings.py        # 5. Next root subdirectory
main.py              # 6. Root-level files last
```

Create a summary table:

```markdown
| # | File | +/- | Purpose |
|---|------|-----|---------|
| 1 | `path/to/file1.py` | +50/-10 | Brief purpose |
| 2 | `path/to/file2.py` | +20/-5 | Brief purpose |
```

### Step 3: Generate Tour Stops

For each significant change, create a "tour stop" with:

```markdown
### Stop N: [Descriptive Title] (Lines X-Y)

[Code snippet or reference]

**Context:** Why this code exists, what problem it solves

**Notice:** What the reviewer should observe about this change

**Review:**
- [Checkbox] Items that need careful review
- [Warning] Potential issues or risks
- [Check] Items that look good
```

### Step 4: Prioritize Review Areas

Use these markers:
- **RIGOROUSLY REVIEW** - Security, data integrity, breaking changes
- **Notice** - Important but straightforward changes
- **Context** - Background information
- **Warning** - Potential issues or edge cases

### Step 5: Create Summary Checklist

End with actionable review checklist:

```markdown
## Summary Checklist

| Area | Status | Action |
|------|--------|--------|
| Core logic | [Status] | [Action needed] |
| Error handling | [Status] | [Action needed] |
| Tests | [Status] | [Action needed] |
```

## Output Format

```markdown
# PR #[NUMBER] Review Tour Guide

## File Order (as shown in GitHub UI)

| # | File | +/- | Purpose |
|---|------|-----|---------|
| 1 | `file1.py` | +50 | Description |

---

## File 1: `path/to/file1.py`

**This is the [main/supporting] file. [Brief overview].**

---

### Stop 1: [Section Title] (Lines X-Y)

```python
# Relevant code snippet (abbreviated)
```

**Context:** [Why this exists]

**Notice:** [What to observe]

**Review:**
- [Review point]
- [Warning if any]

---

### Stop 2: [Next Section] (Lines A-B)

[Continue pattern...]

---

## Summary Checklist

| Area | Status | Action |
|------|--------|--------|
| Item | Status | Action |
```

## Tour Stop Guidelines

### Grouping Rules

1. **One function/class per stop** - Don't mix unrelated changes
2. **Max ~25 lines of code** - Keep stops digestible
3. **Group related small changes** - Multiple one-liners can share a stop
4. **Separate concerns** - Config changes vs. logic changes vs. tests

### What to Call Out

**Always mention:**
- Breaking changes to public APIs
- Security-sensitive code (auth, crypto, user input)
- Database schema changes
- External service integrations
- Error handling patterns
- Performance implications

**Highlight patterns:**
- Code that duplicates existing functionality
- Missing error handling
- Hardcoded values that should be configurable
- Tests that don't actually test the change

### Context Sources

Provide context from:
- Linked issue/ticket description (GitHub Issues, Jira, Linear, etc.)
- PR description and commits
- Related code in the codebase
- Previous implementations being replaced

## Example Tour Stop

```markdown
### Stop 7: Row Processor - Column Count (Lines 802-830) - CRITICAL BUG FIX

```python
def _process_column_count_row(self, row: dict) -> dict:
    table_rk = _get_snowflake_table_rk(
        table, self.is_instance_default, self.instance_id
    )
    column_rk = _get_column_rk_from_table_rk(table_rk, column) if table_rk else None
    #                                                         ^^^^^^^^^^^^^^^^^^^^^^
```

**Context:** This is the bug fix from commit `a187cd4c`. Previously, when `table_rk` was `None`, `_get_column_rk_from_table_rk(None, column)` would return `"none/column_name"` - a string that bypassed skip logic.

**Review:**
- Good fix - now `column_rk` is `None` when `table_rk` is `None`
- **Verify:** Does the original class have this same bug? If so, should it be fixed there too?
```

## Comparison with Linked Issue/Ticket

When a linked issue or ticket is provided (GitHub Issue, Jira, Linear, etc.):

### Step 1: Detect and Fetch Ticket Details

**GitHub Issues:**
```bash
gh issue view <ISSUE_NUMBER> --repo <OWNER/REPO> --json title,body,labels,assignees
```

**Jira:**
- Use Atlassian MCP: `mcp__atlassian__getJiraIssue`
- Or Jira REST API

**Linear:**
- Use Linear MCP or GraphQL API
- Extract issue details from Linear URL

**Other Trackers:**
- Use appropriate MCP integration if available
- Fall back to URL/description provided by user

### Step 2: Extract and Compare Requirements

1. **Parse requirements** from issue/ticket description
2. **Create comparison table:**

```markdown
### Issue vs. Implementation Comparison

| Requirement | Status | Notes |
|-------------|--------|-------|
| Item from issue | Implemented/Missing/Partial | Details |
```

3. **Call out discrepancies** between issue requirements and implementation
4. **Note any scope changes** - features added or removed from original spec

## Review Modes

The skill supports three modes, with defaults based on operation context and confidence:

### Mode Selection Logic

```
1. Detect operation mode (CLI vs pass-through)
2. Assess confidence in review findings
3. Select mode based on:
   - High confidence + Pass-through → Post inline comments directly
   - High confidence + CLI → Display locally, offer to post
   - Low confidence (any mode) → Display locally, discuss before posting
```

### Mode 1: CLI Display (Default for interactive CLI)
Display the tour guide in the Claude session. User reviews in terminal.

**Use when:**
- Running in Claude Code CLI interactively
- Low confidence in findings (need discussion)
- User wants to review before posting

### Mode 2: Inline PR Comments (Default for pass-through when confident)
Post inline comments directly on the PR using conventional comment labels.

**Use when:**
- High confidence in findings
- Running via pass-through tool (OpenClaw, automation)
- User explicitly requests inline comments

### Mode 3: PR Comments ("Tour Guide" Mode)
Leave `# Reviewer Note` comments on the PR to guide human reviewers through the UI.

**Use when:** Team collaboration, asynchronous review, onboarding reviewers.

### Confidence-Based Behavior

**High Confidence (post directly in pass-through mode):**
- Clear, well-scoped changes
- Familiar patterns and codebase conventions
- No ambiguous or risky areas
- Comments are objective observations or standard suggestions

**Low Confidence (always discuss locally first):**
- Complex or unfamiliar code patterns
- Potential security or architectural concerns
- Ambiguous requirements or unclear intent
- Comments that might need human judgment on tone/priority

---

## Posting Inline PR Comments

### Workflow Based on Confidence and Mode

The workflow varies based on confidence level and operation mode:

#### High Confidence + Pass-Through Mode: Post Directly

When running via delegation (OpenClaw, automation) AND confident in findings:

```
1. COMPLETE REVIEW
   - Generate full tour guide (all files, all stops)
   - Assess confidence in each finding

2. POST COMMENTS DIRECTLY
   - Batch post all comments at once
   - Verify each landed on correct line
   - Report summary of posted comments
```

#### Low Confidence OR CLI Mode: Discuss First

When confidence is low OR running interactively in CLI:

```
1. COMPLETE LOCAL REVIEW
   - Generate full tour guide (all files, all stops)
   - Identify all issues, suggestions, and considerations
   - Compile into a summary for human review

2. PRESENT FINDINGS TO HUMAN
   - Show summary of all proposed comments
   - Include: file, line, label, message for each
   - Flag any low-confidence items
   - Ask: "Would you like me to post these as inline
          comments on the PR?"

3. HUMAN APPROVAL
   - Human reviews proposed comments
   - Human may: approve all, modify some, reject some
   - Human confirms which comments to post

4. BATCH POST APPROVED COMMENTS
   - Post all approved comments at once
   - Verify each landed on correct line
   - Report back with links to posted comments
```

**Why discuss first for low confidence:**
- Prevents posting comments the human might disagree with
- Allows human to adjust tone, wording, or priorities
- Ensures comments represent the human reviewer's voice
- Batch posting is less noisy for PR author

### Prerequisites

```bash
# Get PR head commit SHA (required for comments)
gh pr view <PR_NUMBER> --json headRefOid --jq '.headRefOid'

# Save diff to temp file for analysis
gh pr diff <PR_NUMBER> > /tmp/pr_diff_<PR_NUMBER>.txt
```

### Conventional Comment Labels

Use these prefixes for professional code review comments:

| Label | Use Case | Example |
|-------|----------|---------|
| `suggestion:` | Improvements, refactoring ideas | "suggestion: Extract to shared constants file" |
| `thought:` | Considerations, questions for discussion | "thought: Verify backend API compatibility" |
| `nit:` | Minor style/formatting issues | "nit: Use Tailwind classes instead of inline styles" |
| `question:` | Clarification needed | "question: Is this intentional behavior?" |
| `praise:` | Good patterns worth noting | "praise: Nice use of early returns" |
| `issue:` | Bugs or problems found | "issue: This will throw if array is empty" |

### Calculating Diff Positions

The GitHub API uses `position` (line number within the file's diff section), NOT the actual file line number.

**Strategy:**

1. **Save diff to temp file:**
   ```bash
   gh pr diff <PR_NUMBER> > /tmp/pr_diff_<PR_NUMBER>.txt
   ```

2. **Find where file starts in diff:**
   ```bash
   grep -n "^diff --git.*<filename>" /tmp/pr_diff_<PR_NUMBER>.txt
   # Example: Returns "38:" meaning file diff starts at line 38
   ```

3. **Find target line in diff:**
   ```bash
   grep -n "<search_pattern>" /tmp/pr_diff_<PR_NUMBER>.txt
   # Example: Returns "81:" meaning target is at diff line 81
   ```

4. **Calculate position:**
   ```
   position = target_diff_line - file_start_diff_line
   # Example: position = 81 - 38 = 43
   ```

### Posting Comments via gh api

**JSON payload approach (handles complex comment bodies):**

```bash
cat > /tmp/review_comment.json << 'EOF'
{
  "body": "**suggestion:** Consider extracting `PRODUCT_COLORS` to a shared constants file.\n\nThis configuration is duplicated in 4 files.",
  "commit_id": "<HEAD_COMMIT_SHA>",
  "path": "src/path/to/file.tsx",
  "position": 43
}
EOF

gh api repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/comments --input /tmp/review_comment.json
```

**Verify comment placement:**
```bash
# Check which line the comment landed on
gh api repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/comments \
  --jq '.[] | {file: .path, line: .line, body: .body[0:50]}'
```

### Common Position Calculation Examples

**For a file like `api.ts` with multiple hunks:**

```
Diff structure:
Line 1:  diff --git a/src/api.ts
Line 5:  @@ -36,6 +36,8 @@   <- First hunk
Line 14: @@ -185,6 +187,14 @@ <- Second hunk
Line 29: @@ -602,6 +612,8 @@   <- Third hunk
Line 34: +    sort_order?: string;  <- Target line

Position for sort_order = 34 - 4 (header lines) = 30
```

### Cleanup

```bash
# Delete duplicate/incorrect comments
gh api -X DELETE repos/<OWNER>/<REPO>/pulls/comments/<COMMENT_ID>

# List your comments to verify
gh api repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/comments \
  --jq '.[] | select(.user.login == "<YOUR_USERNAME>") | {id, file: .path, line: .line}'
```

### Fetching File Content from PR Branch

When local files don't exist (PR not checked out), fetch from GitHub:

```bash
# Get PR branch name
BRANCH=$(gh pr view <PR_NUMBER> --json headRefName --jq '.headRefName')

# Fetch file content and find line numbers
gh api repos/<OWNER>/<REPO>/contents/<FILE_PATH>?ref=<BRANCH> \
  --jq '.content' | base64 -d | grep -n "<SEARCH_PATTERN>"
```

This is useful for:
- Verifying exact line numbers in the new code
- Finding additional context not visible in the diff
- Confirming patterns exist in multiple files

### Complete Workflow Example

```bash
# 1. Get commit SHA
COMMIT=$(gh pr view 1999 --json headRefOid --jq '.headRefOid')

# 2. Save diff
gh pr diff 1999 > /tmp/pr_diff_1999.txt

# 3. Find position (example: PRODUCT_COLORS in DatabricksCostChartTooltip.tsx)
FILE_START=$(grep -n "^diff --git.*DatabricksCostChartTooltip" /tmp/pr_diff_1999.txt | cut -d: -f1)
TARGET=$(grep -n "PRODUCT_COLORS" /tmp/pr_diff_1999.txt | head -1 | cut -d: -f1)
POSITION=$((TARGET - FILE_START))

# 4. Post comment
cat > /tmp/comment.json << EOF
{
  "body": "**suggestion:** This configuration is duplicated in 4 files. Consider extracting to shared constants.",
  "commit_id": "$COMMIT",
  "path": "src/pages/databricks/components/DatabricksCostChartTooltip.tsx",
  "position": $POSITION
}
EOF

gh api repos/<OWNER>/<REPO>/pulls/1999/comments --input /tmp/comment.json
```

### Troubleshooting

**Comment lands on wrong line:**
- Position calculation was off
- Delete incorrect comment: `gh api -X DELETE repos/.../pulls/comments/<ID>`
- Recalculate position and retry

**"position" not found error:**
- The line may not be in the diff (unchanged code)
- Can only comment on lines that appear in the diff
- Try finding a nearby changed line

**Multiple hunks in file:**
- Position is cumulative across all hunks
- Count from `diff --git` line, not from each `@@` hunk header

---

## Approval Workflow

When user requests "review and approve" or similar:

### CRITICAL: Never Auto-Approve

**Do NOT automatically approve a PR.** Even if the user says "review and approve", follow this workflow:

1. **Complete the full review** using the tour guide process
2. **Assess the PR** for red flags, risks, and correctness
3. **Present findings** to the user with your confidence assessment
4. **Ask for user's confidence level** before approving

### Approval Decision Tree

```
1. Complete review
   ↓
2. Any red flags found?
   → YES: Present concerns, do NOT approve, recommend changes
   → NO: Continue to step 3
   ↓
3. Assess risk level and correctness confidence
   ↓
4. Present to user:
   "No red flags found. [Summary of changes].
    Risk level: [low/medium/high]
    My confidence: [high/medium/low]

    Would you like me to approve? Please confirm your confidence level."
   ↓
5. User confirms confidence
   ↓
6. Approve with appropriate semantic message
```

### Semantic Approval Messages

Use these approval messages based on confidence level:

| Message | Meaning | When to Use |
|---------|---------|-------------|
| **LGTM** | Looks Good To Me | High confidence. Code is correct, well-written, follows best practices. Would approve without hesitation. |
| **lgtm** | looks good to me | Lower confidence/less emphatic. Code appears correct but haven't verified exhaustively. Quieter approval. |
| **LFTM** | Looks Fine To Me | High confidence shipping won't break anything. No major concerns, but not necessarily exceptional code. Pragmatic approval. |
| **lftm** | looks fine to me | Lower confidence. No red flags visible, but recommend user has fully tested and is confident before merging. |

### Approval Criteria

**Approve (LGTM/lgtm) when:**
- Code logic is verifiably correct
- Tests cover the changes adequately
- No security concerns
- Follows codebase conventions
- PR description matches implementation

**Approve (LFTM/lftm) when:**
- No red flags or obvious issues
- Unable to fully verify correctness without running tests
- Changes are low-risk (config, copy, minor refactors)
- User has context you don't have

**Do NOT approve when:**
- Any security concerns exist
- Logic errors are present
- Tests are missing for critical paths
- Breaking changes aren't documented
- You have unresolved questions about intent

### Posting Approval

```bash
# Approve with comment
gh pr review <PR_NUMBER> --approve --body "LGTM - [brief summary of why]"

# Or with more detail
gh pr review <PR_NUMBER> --approve --body "$(cat <<'EOF'
LGTM

✓ Logic looks correct
✓ Tests cover the changes
✓ Follows existing patterns

Ship it!
EOF
)"
```

---

## Quality Guidelines

### DO:
- Lead with the most important/risky changes
- Provide enough context for someone unfamiliar with the code
- Use specific line numbers and function names
- Highlight both good patterns and concerns
- End with actionable next steps
- Use conventional comment labels for consistency
- Verify comment positions landed correctly

### DON'T:
- List every line changed
- Provide context without review guidance
- Skip over complex logic
- Assume reviewer knows the codebase
- Leave concerns without suggested actions
- Use scary language like "Risk" - prefer neutral terms like "Consideration"

---

**Version**: 1.0.0
