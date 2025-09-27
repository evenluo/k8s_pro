# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Specify-based project that uses a structured workflow for feature development. The project follows a specification-driven development process with phases: specification → planning → task generation → implementation.

## Core Commands

### Feature Development Workflow

1. **Create Feature Specification**: `/specify <feature description>`
   - Creates a new feature branch and specification document
   - Output: `specs/<branch-name>/spec.md`

2. **Create Implementation Plan**: `/plan`
   - Generates technical design from specification
   - Creates research.md, data-model.md, contracts, and quickstart.md
   - Must run after specification is complete

3. **Generate Tasks**: `/tasks`
   - Creates ordered task list from design artifacts
   - Output: `specs/<branch-name>/tasks.md`
   - Must run after plan is complete

4. **Execute Implementation**: `/implement`
   - Executes tasks from tasks.md
   - Implements the feature following the plan

5. **Analyze Consistency**: `/analyze`
   - Validates consistency across spec, plan, and tasks
   - Non-destructive check for quality assurance

6. **Clarify Requirements**: `/clarify`
   - Identifies and resolves underspecified areas
   - Asks targeted questions and updates spec

7. **Update Constitution**: `/constitution`
   - Create or update project principles
   - Keeps templates in sync with principles

## Project Structure

```
.specify/                 # Methodology configuration
├── templates/           # Document templates
│   ├── spec-template.md
│   ├── plan-template.md
│   ├── tasks-template.md
│   └── agent-file-template.md
├── scripts/bash/        # Automation scripts
│   ├── create-new-feature.sh
│   ├── setup-plan.sh
│   └── update-agent-context.sh
└── memory/              # Project constitution and principles

.claude/commands/        # Command definitions for slash commands

specs/                   # Feature specifications (created per feature)
└── <branch-name>/
    ├── spec.md          # Feature specification
    ├── plan.md          # Implementation plan
    ├── research.md      # Technical research
    ├── data-model.md    # Data models
    ├── quickstart.md    # Quick start guide
    ├── contracts/       # API contracts
    └── tasks.md         # Task list

src/                     # Source code (structure depends on project type)
tests/                   # Test files
```

## Development Workflow

1. **Starting a new feature**:
   - Use `/specify` with a clear description
   - Review generated spec.md for completeness
   - Use `/clarify` if requirements need refinement

2. **Planning implementation**:
   - Run `/plan` after spec is ready
   - Review research.md for technical decisions
   - Check contracts/ for API definitions

3. **Task execution**:
   - Run `/tasks` to generate task list
   - Use `/implement` for automated execution
   - Or execute tasks.md manually

4. **Quality checks**:
   - Run `/analyze` to validate consistency
   - Review all generated documentation
   - Ensure tests are created before implementation

## Key Scripts

- **create-new-feature.sh**: Creates feature branch and initializes spec
  - Usage: `.specify/scripts/bash/create-new-feature.sh --json "<feature description>"`
  - Returns JSON with branch name and spec file path

- **update-agent-context.sh**: Updates agent-specific files (CLAUDE.md, etc.)
  - Usage: `.specify/scripts/bash/update-agent-context.sh claude`
  - Maintains recent changes and tech stack info

## Important Notes

- All feature work starts from specification (`/specify`)
- Markdown 文档已启用目录功能（md 支持 `[TOC]`），编辑时请保留文首标签以确保导航可用。
- 引入新概念、新工具或关键术语时，请在相应 Markdown 文档添加“## 概念卡速记”段落；每张卡片采用带 `📌` 的引用块，并按照“定义 → 在课程中的作用 → 快速命令/提示”顺序说明，保持学习材料的节奏一致。
- Follow the phase order: specify → plan → tasks → implement
- Each phase validates prerequisites before execution
- Templates enforce consistent structure across features
- Constitution principles guide all design decisions
