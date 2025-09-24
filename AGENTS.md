# Repository Guidelines

## Project Structure & Module Organization
- `specs/<feature-id>` stores each curriculum feature (e.g., `specs/001-k8s`) with `spec.md`, `plan.md`, `tasks.md`, and supporting docs; keep the folder self-contained and numbered.
- `.specify/scripts/bash` holds automation helpers shared by every agent—keep them POSIX-friendly and idempotent.
- Agent prompt baselines live in `.codex/prompts`, `.claude/commands`, and companion files (`CLAUDE.md`, `AGENTS.md`); edit them through the context updater to avoid drift.

## Build, Test, and Development Commands
- `./.specify/scripts/bash/create-new-feature.sh "describe the capability"` scaffolds the next `NNN-short-slug` feature directory and branch when git is available.
- `./.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks` confirms all mandatory docs exist and are ready for review.
- `./.specify/scripts/bash/update-agent-context.sh codex` refreshes agent briefs after plan changes; omit the argument to update every agent file.
- Optional lint gate: `npx markdownlint "**/*.md"` catches heading and spacing issues before you push.

## Coding Style & Naming Conventions
- Structure Markdown with clear heading levels, short paragraphs, and fenced `bash` blocks for commands; keep emoji purposeful.
- Follow the curriculum voice: explanatory prose primarily in Chinese with English technical terms (per FR-009) and one idea per subsection.
- Branch and file names remain lowercase and hyphenated (`001-feature`, `data-model.md`); scripts stay executable and use snake-case.

## Testing Guidelines
- Treat `check-prerequisites.sh` as the readiness check—aim for all ✓ before opening a PR.
- Preview Markdown (GitHub or VS Code) to confirm Mermaid diagrams, tables, and code blocks render correctly.
- Validate every command in `quickstart.md` or `contracts/` snippets; update both docs and scripts if the command output changes.

## Commit & Pull Request Guidelines
- Write concise, present-tense commits, ideally prefixed with the feature code (`001-k8s: clarify quickstart prerequisites`).
- PRs should link the source spec or plan, call out learner impact, and attach screenshots/output when altering quickstart flows or scripts.
- Confirm linting and prerequisite checks in the PR description and request review from another agent maintainer.

## Agent-Specific Notes
- Re-run `update-agent-context.sh` whenever `plan.md` or `tasks.md` changes so Codex, Claude, and peers stay aligned.
- Prefer repo-relative paths and avoid hard-coded environments to keep automation portable across agents.
