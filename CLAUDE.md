# CLAUDE.md

## Project Overview

**Site Builder Agents** is a Claude Code skills plugin that installs a team of 14 specialized AI agents and a master orchestrator into any client website project, handling the complete website design lifecycle from business analysis through deployment.

## Repository Structure

This is a mono-repo.

<!-- fullstack-dev:start -->

### Repos

This is a mono-repo. Key directories:
- **`agents/`** -- 14 phase-specific agent definitions (discovery, architect, designer, developer, content, audits, deploy, etc.)
- **`skills/site-builder/`** -- the installable skill: orchestrator `SKILL.md`, framework `adapters/`, and `reference/` standards
- **`templates/`** -- scaffolding assets (animations, video handling) used by the developer agent
- **`docs/`** -- project-level documentation (this file's supporting docs)

### Tech Stack

No application language/runtime — this repo is Markdown-based Claude Code configuration only (no `package.json`, no build tooling). See `docs/project/tech-stack.md` for full detail, including the downstream framework adapters (Astro, Next.js, Vue, React) the plugin can scaffold into client projects.

### Build & Development Commands

#### Site Builder plugin (`.`)

```bash
# No install/build/test commands -- this repo ships Markdown only.
# Distribution is via the `skills` CLI:
npx skills add https://github.com/RANKME-TOP/site-builder-plugin --skill site-builder   # install into a client project
npx skills update site-builder                                                          # update an installed copy
```

### Git Workflow

1. Work on `local-dev` branch -- never commit directly to `master`
2. Commit using Conventional Commits: `<type>(<scope>): <summary>`
3. When pushing: `git push origin local-dev:<type>/<name>`
4. Create PR targeting `master` using MCP tools
5. Never push `local-dev` to remote
6. Never create local feature/fix branches
7. Use `/git sync` to pull latest from `master`

### GitHub Operations

**ALWAYS use `mcp__github__*` MCP tools for GitHub operations** (issues, PRs, repos, branches, search). Never use the CLI -- the MCP server is configured per-workspace with its own auth token.

### Architecture Reference -- Lookup Order

When you need to understand the codebase:

1. **Read CONTEXT.md** -- domain model (agents, skills, adapters), instruction "data flow", conventions
2. **Read docs/project/architecture.md** -- unified system architecture
3. **Read ARCHITECTURE.md** -- repo structure, patterns, entry points
4. **Read source files** -- only when the above don't have what you need

### Documentation Structure

```text
docs/
+-- project/     # Architecture, tech stack
+-- specs/       # Design specs from brainstorming
+-- plans/       # Implementation plans
```

<!-- fullstack-dev:end -->
