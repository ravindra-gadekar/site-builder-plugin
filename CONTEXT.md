# CONTEXT.md

## Domain Model

### Entities

| Entity | Description | Source |
|---|---|---|
| Agent | A specialized AI persona (e.g. discovery, architect, designer, developer, deploy, seo-indexing) that performs one stage of the website build lifecycle | `agents/*.md` |
| Skill | A packaged, reusable set of instructions installed via the `skills` CLI that Claude Code loads to perform a workflow | `skills/site-builder/SKILL.md`, `.agents/skills/*` |
| Adapter | A framework-specific implementation of the site-builder pipeline (Astro, Next.js, Vue, React) | `skills/site-builder/adapters/*.md` |
| Template | Reusable code/config scaffolding (animations, video handling) referenced by the developer agent | `templates/**` |
| Reference Doc | Supporting standards/checklists (design principles, quality gates, audit standards, phases) consulted by agents during a build | `skills/site-builder/reference/*.md` |

### Relationships

- The **master orchestrator** (`/site-builder`) sequences 15 **Agents** through the website build lifecycle (business analysis -> design -> development -> deployment).
- Each **Agent** may consult one or more **Reference Docs** and, for the developer agent, an **Adapter** matching the target framework.
- **Templates** are consumed by the developer agent when scaffolding a client site.
- The plugin itself is distributed and updated via the `skills` CLI (`skills-lock.json` tracks the installed skill versions/hashes), separate from the `site-builder` skill this repo authors and ships.

### Glossary

| Term | Meaning |
|---|---|
| Site Builder | The end-to-end pipeline this plugin installs into a client website project |
| Orchestrator | The `/site-builder` command that detects project state and drives the pipeline |
| Build Mode | One of Demo / Prod — determines the PR target branch and page scope for a build |
| Client project | The downstream repository where this plugin is installed (`npx skills add ...`) and where agents operate |

## Data Flow

This repo does not run an application at runtime — it is a documentation/instruction plugin consumed by Claude Code. "Data flow" here describes how instructions flow, not application data.

### Request Lifecycle

1. A developer runs `npx skills add https://github.com/ravindra-gadekar/site-builder-plugin --skill site-builder` inside a client website project.
2. The developer invokes `/site-builder` inside Claude Code.
3. The orchestrator skill (`skills/site-builder/SKILL.md`) inspects the client project's current state and dispatches the appropriate agent (`agents/*.md`) for the next lifecycle phase.
4. The dispatched agent reads relevant reference docs and, for code-producing phases, the framework adapter matching the client project's stack.
5. The agent performs its phase (analysis, design, content, code, audits, deployment) directly against the client project's files.

### Event Flow (if applicable)

Not applicable — this is a single-session, agent-driven workflow, not an event-driven system.

## Conventions

### Naming

| Context | Convention | Example |
|---|---|---|
| Agent files | `<role>-agent.md` | `developer-agent.md` |
| Adapter files | `<framework>.md` under `skills/site-builder/adapters/` | `adapters/nextjs.md` |
| Reference docs | kebab-case topic name | `reference/quality-gates.md` |

### Patterns

- **Phase-based agent dispatch**: one specialized agent per lifecycle stage, coordinated by a single orchestrator skill.
- **Framework adapters**: shared agent logic (e.g. developer-agent) branches into a framework-specific adapter doc rather than duplicating per-framework agents.
- **Reference-doc lookup**: agents defer detailed standards (accessibility, SEO, quality gates) to shared reference docs instead of inlining them per agent.

### Decisions

- No application code lives in this repo by design — it is purely Markdown-based Claude Code configuration (skills, agents, templates, reference docs), so no language/framework/build tooling is required for the plugin itself.
- Distribution is via the `skills` CLI rather than npm, since the deliverable is Claude Code instructions, not a runnable package.
