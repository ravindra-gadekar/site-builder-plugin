# Phase 5: Documentation Consistency

**Repo:** site-builder-plugin
**Depends on:** Phase 2 (`agents/seo-indexing-agent.md` must exist — these tasks bump the agent count from 14 to 15, which is only true once the file exists)
**Delivers:** Every project doc that states the plugin's agent count (`README.md`, `CONTEXT.md`, `docs/project/architecture.md`, `ARCHITECTURE.md`, `CLAUDE.md`) reads 15, not 14, and `README.md`'s pipeline/roster sections reflect the new 11th phase and 15th agent.

## File Structure

```
README.md                       [MODIFY]
CONTEXT.md                      [MODIFY]
ARCHITECTURE.md                 [MODIFY]
CLAUDE.md                       [MODIFY]
docs/project/
└── architecture.md             [MODIFY]
```

### Task 1: `README.md`

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: `agents/seo-indexing-agent.md` (Phase 2 Task 1 — the 15th agent being added to the roster table), `phases.md` Phase 11 entry (Phase 2 Task 2 — the pipeline list addition)
- Produces: none (leaf documentation)

**Acceptance Criteria:** AC21 (README.md updated from "14 agents" to "15 agents" with `seo-indexing-agent` in roster tables)

**Steps (Documentation: Write-and-review):**

1. **Write content:**

   a. Line 3: `"...installs a team of 14 specialized AI agents..."` → `"...installs a team of 15 specialized AI agents..."`.

   b. `### 10-Phase Pipeline` heading → `### 11-Phase Pipeline`; inside the fenced pipeline diagram, add a line after `Phase 10: ANALYTICS  → ...`:
      ```
      Phase 11: AUTO-INDEXING → Git-derived sitemap lastmod, inline IndexNow CI notification, RSS/Atom feed
      ```
      "AUTO-INDEXING" (13 chars) is longer than every existing phase label — re-pad all 11 lines' `→` arrows to a common column once the new line is in place, so the block stays visually aligned (the existing 10 lines are hand-aligned; don't leave the new line as the only misaligned one).

   c. Approval Gates line: `"5 user approval gates (Discover, Architect, Design, Deploy, Analytics) and 1 quality gate (all 6 audits must pass)."` → `"6 user approval gates (Discover, Architect, Design, Deploy, Analytics, Auto-Indexing) and 1 quality gate (all 6 audits must pass)."`

   d. `## 14 Agents` heading → `## 15 Agents`.

   e. After the existing "### Integration Team" table (ending with row `14 | deploy-agent | Sonnet | CI/CD pipeline, staging deploy, rollback plan`), add:
      ```markdown
      ### Indexing
      | # | Agent | Model | Role |
      |---|-------|-------|------|
      | 15 | seo-indexing-agent | Sonnet | Git-derived sitemap lastmod, inline IndexNow CI notification, RSS/Atom feed |
      ```

   f. Project structure tree: `├── agents/                          # 14 specialist agents` → `├── agents/                          # 15 specialist agents`; add a new line after `│   ├── deploy-agent.md`:
      ```
      │   └── seo-indexing-agent.md
      ```
      (and change the previous `│   └── deploy-agent.md` line to `│   ├── deploy-agent.md` since it's no longer the last entry).

2. **Verify references** — Confirm the pipeline diagram now lists exactly 11 `Phase N:` lines. Confirm the agent roster tables sum to 15 rows across all sections (5 Build Team + 6 Audit Squad + 3 Integration Team + 1 Indexing = 15). Confirm the project structure tree's `agents/` block lists 15 `.md` filenames.

3. **Commit** — `docs: bump README.md to 15 agents / 11-phase pipeline`

---

### Task 2: `CONTEXT.md`

**Files:**
- Modify: `CONTEXT.md`

**Interfaces:**
- Consumes: `agents/seo-indexing-agent.md` (Phase 2 Task 1)
- Produces: none (leaf documentation)

**Acceptance Criteria:** AC21 (CONTEXT.md agent count + Entities table updated)

**Steps (Documentation: Write-and-review):**

1. **Write content:**

   a. `"The master orchestrator (\`/site-builder\`) sequences 14 Agents through the website build lifecycle..."` → `"...sequences 15 Agents through the website build lifecycle..."`.

   b. Entities table, Agent row description: `"(e.g. discovery, architect, designer, developer, deploy)"` → `"(e.g. discovery, architect, designer, developer, deploy, seo-indexing)"`.

2. **Verify references** — Confirm exactly these two lines changed; no other section of `CONTEXT.md` (Relationships, Glossary, Data Flow, Conventions) references an agent count or needs a Phase 11 mention per the spec's stated scope.

3. **Commit** — `docs: bump CONTEXT.md to 15 agents`

---

### Task 3: `docs/project/architecture.md`

**Files:**
- Modify: `docs/project/architecture.md`

**Interfaces:**
- Consumes: `agents/seo-indexing-agent.md` (Phase 2 Task 1)
- Produces: none (leaf documentation)

**Acceptance Criteria:** AC21 (docs/project/architecture.md agent count in System Overview updated)

**Steps (Documentation: Write-and-review):**

1. **Write content** — `"It installs a master orchestrator (\`/site-builder\`) and 14 specialized agents into a client website project."` → `"...and 15 specialized agents into a client website project."`.

2. **Verify references** — Confirm the Service Map table and Services/Integrations sections (which don't mention a count) are untouched — only the System Overview sentence changed, per the spec's explicit "Agent count in System Overview" scope.

3. **Commit** — `docs: bump docs/project/architecture.md to 15 agents`

---

### Task 4: `ARCHITECTURE.md` (root) and `CLAUDE.md`

**Files:**
- Modify: `ARCHITECTURE.md`
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: `agents/seo-indexing-agent.md` (Phase 2 Task 1)
- Produces: none (leaf documentation)

**Acceptance Criteria:** AC21 (extended, by user confirmation during plan generation, to also cover the same stale "14 agents" count in these two files — not in the spec's literal file list, but the same underlying requirement)

**Steps (Documentation: Write-and-review):**

1. **Write content:**

   In `ARCHITECTURE.md` (root):
   - `"It packages a master orchestrator and 14 specialized agents that together run the full lifecycle..."` → `"...and 15 specialized agents..."`.
   - `├── agents/              # 14 phase-specific agent definitions (Markdown)` → `├── agents/              # 15 phase-specific agent definitions (Markdown)`.

   In `CLAUDE.md`:
   - `"**Site Builder Agents** is a Claude Code skills plugin that installs a team of 14 specialized AI agents..."` → `"...15 specialized AI agents..."` (this line is outside the `<!-- fullstack-dev:start -->`/`<!-- fullstack-dev:end -->` marker block, safe to hand-edit permanently).
   - Inside the marker block: `"**\`agents/\`** -- 14 phase-specific agent definitions (discovery, architect, designer, developer, content, audits, deploy, etc.)"` → `"**\`agents/\`** -- 15 phase-specific agent definitions (discovery, architect, designer, developer, content, audits, deploy, seo-indexing, etc.)"`. This edit is inside the auto-refreshed marker block — safe to make now (the /project skill's doc-refresh recomputes the actual count from the `agents/` directory on its next run, so this one-time correction won't drift).

2. **Verify references** — Confirm `ARCHITECTURE.md`'s Purpose paragraph and Directory Structure tree both now read 15. Confirm `CLAUDE.md`'s edit inside the marker block did not touch the `<!-- fullstack-dev:start -->`/`<!-- fullstack-dev:end -->` comment lines themselves — only the text between them.

3. **Commit** — `docs: bump ARCHITECTURE.md and CLAUDE.md to 15 agents`

---

## Phase 5 Complete

Every project doc that states the plugin's agent count now reads 15, `README.md`'s pipeline diagram and approval-gate count reflect the new 11-phase pipeline, and the `seo-indexing-agent` is discoverable in the README's agent roster table. This is the final phase — Auto-Indexing (Phase 11) is fully specified, implemented in the orchestrator, and documented end-to-end.

**Next:** Plan complete.
