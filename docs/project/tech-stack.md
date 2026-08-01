# Tech Stack

## Languages & Frameworks

| Technology | Version | Used In | Purpose |
|---|---|---|---|
| Markdown | n/a | `agents/`, `skills/`, `templates/`, `docs/` | Format for all agent definitions, skill instructions, and reference docs |
| Claude Code Skills | n/a | `skills/site-builder/` | Packaging format the plugin ships as (`SKILL.md` + `reference/` + `adapters/`) |

_No application language/runtime is used in this repo — it contains no `package.json` or build tooling. It is a documentation/instruction plugin, not a running service._

## Databases

_None. This repo has no data storage of its own._

## DevOps & Infrastructure

| Tool | Purpose |
|---|---|
| `skills` CLI (`npx skills add/update`) | Installs and updates this plugin's skills into client projects; tracks installed versions in `skills-lock.json` |
| Git | Version control for this plugin's source |

## AI/LLM Integration

| Provider/Tool | Purpose |
|---|---|
| Claude Code (Anthropic) | Runtime the plugin's agents and skills execute within |
| context7 MCP | Fetches current framework docs for the developer agent when scaffolding client sites |

## Key Libraries

_None — no dependency manifest exists in this repo._

## Downstream Adapters (what the plugin generates, not this repo's own stack)

The `developer-agent` supports scaffolding client sites in the following frameworks, documented per-adapter under `skills/site-builder/adapters/`:

| Adapter | Purpose |
|---|---|
| Astro | Static/content-heavy site scaffolding |
| Next.js | React framework scaffolding |
| Vue | Vue framework scaffolding |
| React | React (non-Next) scaffolding |
