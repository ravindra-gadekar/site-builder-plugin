# Architecture

## System Overview

Site Builder Agents is a Claude Code skills plugin, not a running application. It installs a master orchestrator (`/site-builder`) and 15 specialized agents into a client website project. The orchestrator inspects the client project's current state and dispatches the right agent for the next phase of the website build lifecycle — business analysis, design, content, development, audits, and deployment.

### Service Map

| Service | Repo | Tech | Port/URL |
|---|---|---|---|
| Site Builder plugin (this repo) | `site-builder-plugin` (mono-repo) | Markdown / Claude Code Skills | n/a (installed into client repos, not hosted) |

## Services

### Site Builder plugin

- **Repo:** `.` (root)
- **Purpose:** Ships the `site-builder` skill, its orchestrator, 14 phase agents, framework adapters, and reference standards that together drive a client website build from analysis through deployment.
- **Tech:** Markdown-based Claude Code skill/agent definitions; distributed via the `skills` CLI.
- **Communication:** No network communication of its own — it operates as in-session Claude Code instructions against whatever client repository it is installed into.

## Data Storage

### Databases

_None — the plugin has no data storage of its own. Any databases used are part of the downstream client project the plugin builds, not this repo._

### Caches (if applicable)

None.

### File Storage (if applicable)

None beyond the plugin's own Markdown files and `templates/` scaffolding assets.

## External Integrations

| Integration | Type | Purpose |
|---|---|---|
| context7 | MCP | Developer agent fetches current framework docs when scaffolding client code |
| Image generation MCP | MCP (recommended, not required) | Content agent generates images; otherwise produces content briefs |
| Analytics MCP | MCP (optional) | Centralized analytics connector management |
| GitHub | MCP (`github` server) | PR/issue/repo operations for this plugin's own repo |
| code-review-graph | MCP | Tree-sitter-backed code knowledge graph for token-efficient reviews of this repo |

## Authentication & Authorization

Not applicable — the plugin has no runtime auth of its own. MCP servers (GitHub) authenticate via a personal access token stored in `.claude/settings.local.json` (never committed).

## Deployment

This plugin is not deployed as a service. It is distributed via `npx skills add/update` and consumed inside Claude Code sessions in client projects. Version pinning/updates are tracked per-skill in `skills-lock.json`.
