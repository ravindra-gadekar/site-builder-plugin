# Site Builder Agents Architecture

## Purpose

This repo is a Claude Code skills plugin. It packages a master orchestrator and 14 specialized AI agents that together run the full lifecycle of building a client website — business discovery, architecture, design, content, development, audits (accessibility/SEO/schema/technical), analytics, social integration, and deployment.

## Directory Structure

```
site-builder-plugin/
+-- agents/              # 14 phase-specific agent definitions (Markdown)
+-- skills/
|   +-- site-builder/     # The installable skill: orchestrator SKILL.md, adapters/, reference/
+-- templates/            # Scaffolding assets (animations, video handling) used by the developer agent
+-- docs/                 # fullstack-dev-plugin generated project docs (this init)
+-- .agents/skills/        # Mirror of the fullstack-dev-plugin's own skills (installed via `npx skills add`)
+-- .claude/skills/        # Symlinked view of .agents/skills/ used by this Claude Code session
+-- skills-lock.json       # Tracks installed skill versions/hashes (fullstack-dev-plugin tooling)
+-- README.md              # Install/usage instructions for downstream consumers
```

## Key Patterns

### Phase-based agent dispatch

The `/site-builder` orchestrator inspects a client project's state and hands off to exactly one specialized agent per phase, rather than one monolithic agent handling everything.

**Example:**
```
/site-builder
  -> discovery-agent (business analysis)
  -> architect-agent (site architecture)
  -> designer-agent (visual design)
  -> developer-agent (code, using the matching adapters/<framework>.md)
  -> content-agent, seo-audit-agent, accessibility-audit-agent, ...
  -> deploy-agent
```

### Framework adapters

`developer-agent.md` defers framework-specific scaffolding detail to `skills/site-builder/adapters/{astro,nextjs,vue,react}.md`, so one agent supports four stacks without duplicating logic per framework.

## Entry Points

| Entry Point | Type | Purpose |
|---|---|---|
| `/site-builder` (via `skills/site-builder/SKILL.md`) | Claude Code slash command | Entry point for the entire build pipeline |
| `agents/*.md` | Agent definition | Individually invokable phase agents |

## Dependencies

### Internal (other repos in workspace)

_None — single mono-repo, no internal cross-repo dependencies._

### External

| Dependency | Purpose |
|---|---|
| Claude Code | Runtime this plugin's skills and agents execute within |
| `skills` CLI | Installs/updates this plugin into client projects |
| context7 MCP | Framework documentation lookups during development phase |

## Testing

_None — this repo ships Markdown instructions, not executable code, so there is no automated test suite._
