# Phase 4: Agent Doc-Gate Obligations

**Repo:** site-builder-plugin
**Depends on:** Phase 1 (agent→doc mapping table in `doc-refresh.md` defines what each agent must verify)
**Delivers:** Doc-gate obligation sections added to 6 agent files: `designer-agent.md`, `developer-agent.md`, `content-agent.md`, `social-integration-agent.md`, `analytics-agent.md`, `seo-indexing-agent.md`. Stale `refresh-architecture.mjs` reference removed from `developer-agent.md`.

---

## File Structure

```
agents/
├── designer-agent.md              (modify)
├── developer-agent.md             (modify)
├── content-agent.md               (modify)
├── social-integration-agent.md    (modify)
├── analytics-agent.md             (modify)
└── seo-indexing-agent.md          (modify)
```

---

### Task 1: Designer-Agent + Developer-Agent (BRAND.md Obligations)

**Files:**
- Modify: `agents/designer-agent.md`
- Modify: `agents/developer-agent.md`

**Interfaces:**
- Consumes: Agent→doc mapping from Phase 1 Task 2 (`doc-refresh.md` Section 2) — designer-agent row (BRAND.md, primary owner, all sections) and developer-agent row (ARCHITECTURE.md, CLAUDE.md, BRAND.md verify-only)
- Produces: Doc-gate obligation sections in both agent files. These are consumed by the orchestrator at runtime to know what to verify after each agent completes.

**Acceptance Criteria:** AC-16 (designer-agent BRAND.md obligation), AC-17 (developer-agent BRAND.md + ARCHITECTURE.md + CLAUDE.md obligation)

#### Steps

- [x] **Step 1:** Add a "Doc Gate Obligation" section to `agents/designer-agent.md`. Insert at the end of the file, after the "Output Format" section (after line 401).

  ```markdown
  ## Doc Gate Obligation

  After this agent completes, the orchestrator verifies the following docs
  per the agent-indexed mapping in `skills/site-builder/reference/doc-refresh.md`:

  - **`BRAND.md`** (primary owner) — All sections: colors, typography,
    spacing, component patterns. Content must reflect the design tokens
    produced in `.site-builder/design-system.md`. The designer-agent is the
    primary author of BRAND.md; the developer-agent is secondary/verify-only.
  ```

- [x] **Step 2:** Remove the stale `refresh-architecture.mjs` reference from `agents/developer-agent.md` (line 362).

  Delete this entire bullet:
  ```
  - **Architecture refresh setup:** If the project has `ARCHITECTURE.md` or `BRAND.md` with `<!-- AUTO-GENERATED -->` markers but no `refresh-architecture.mjs` script, set up the refresh script and pre-commit hook during PREPARE phase.
  ```

  This reference is obsolete — the new system uses `<!-- auto:* -->` markers and the `doc-refresh-script.sh` pre-commit hook, not a standalone `refresh-architecture.mjs` script.

- [x] **Step 3:** Add a "Doc Gate Obligation" section to `agents/developer-agent.md`. Append at the end of the file (after the "Framework-Specific Notes" section — note that Step 2's deletion shifts line numbers, so append after the last line).

  ```markdown
  ## Doc Gate Obligation

  After this agent completes, the orchestrator verifies the following docs
  per the agent-indexed mapping in `skills/site-builder/reference/doc-refresh.md`:

  - **`ARCHITECTURE.md`** — Directory Structure, Patterns, Entry Points,
    Dependencies sections must reflect the current codebase state.
  - **`CLAUDE.md`** — Build & Dev commands inside the `<!-- site-builder:start
    -->` marker block must match `package.json` scripts.
  - **`BRAND.md`** (secondary/verify-only, Phase 6 DEVELOP only — not
    Phase 3 PREPARE, when `.site-builder/design-system.md` does not yet
    exist) — Verify token values match `.site-builder/design-system.md`. Do
    not overwrite designer-agent content unless values have diverged during
    implementation.
  ```

- [x] **Step 4:** Verify: designer-agent obligation matches the mapping table row ("BRAND.md, primary owner, all sections"). Developer-agent obligation matches the mapping table row ("ARCHITECTURE.md, CLAUDE.md, BRAND.md verify-only"). The `refresh-architecture.mjs` reference is fully removed with no orphaned text.

- [x] **Step 5:** Commit: `docs(agents): add doc-gate obligations to designer-agent and developer-agent; remove stale refresh-architecture.mjs reference`

---

### Task 2: Content-Agent + Social-Integration-Agent

**Files:**
- Modify: `agents/content-agent.md`
- Modify: `agents/social-integration-agent.md`

**Interfaces:**
- Consumes: Agent→doc mapping from Phase 1 Task 2 — content-agent row (CONTEXT.md, Glossary) and social-integration-agent row (ARCHITECTURE.md, Integrations)
- Produces: Doc-gate obligation sections in both agent files.

**Acceptance Criteria:** AC-18 (content-agent CONTEXT.md Glossary), AC-21 (social-integration-agent ARCHITECTURE.md integrations)

#### Steps

- [x] **Step 1:** Add a "Doc Gate Obligation" section to `agents/content-agent.md`. Insert at the end of the file, after the "Output Format" section (after line 318).

  ```markdown
  ## Doc Gate Obligation

  After this agent completes, the orchestrator verifies the following docs
  per the agent-indexed mapping in `skills/site-builder/reference/doc-refresh.md`:

  - **`CONTEXT.md`** — Glossary section. Any new business terms, industry
    jargon, or entity names introduced in the content
    (`.site-builder/content/*.md`) must be added to the glossary table.
  ```

- [x] **Step 2:** Add a "Doc Gate Obligation" section to `agents/social-integration-agent.md`. Insert at the end of the file, after the "Output Format" section (after line 128).

  ```markdown
  ## Doc Gate Obligation

  After this agent completes, the orchestrator verifies the following docs
  per the agent-indexed mapping in `skills/site-builder/reference/doc-refresh.md`:

  - **`ARCHITECTURE.md`** — Integrations section. Must reflect the social
    platforms connected during this agent's run, as reported in
    `.site-builder/integration-reports/social-integration.md`.
  ```

- [x] **Step 3:** Verify: content-agent obligation matches the mapping table row ("CONTEXT.md, Glossary"). Social-integration-agent obligation matches the mapping table row ("ARCHITECTURE.md, Integrations").

- [x] **Step 4:** Commit: `docs(agents): add doc-gate obligations to content-agent and social-integration-agent`

---

### Task 3: Analytics-Agent + SEO-Indexing-Agent

**Files:**
- Modify: `agents/analytics-agent.md`
- Modify: `agents/seo-indexing-agent.md`

**Interfaces:**
- Consumes: Agent→doc mapping from Phase 1 Task 2 — analytics-agent row (CLAUDE.md, analytics config reference) and seo-indexing-agent row (CLAUDE.md, indexing config reference)
- Produces: Doc-gate obligation sections in both agent files.

**Acceptance Criteria:** AC-19 (analytics-agent CLAUDE.md marker block), AC-20 (seo-indexing-agent CLAUDE.md marker block)

#### Steps

- [x] **Step 1:** Add a "Doc Gate Obligation" section to `agents/analytics-agent.md`. Insert at the end of the file, after the "Output Format" section (after line 192).

  ```markdown
  ## Doc Gate Obligation

  After this agent completes, the orchestrator verifies the following docs
  per the agent-indexed mapping in `skills/site-builder/reference/doc-refresh.md`:

  - **`CLAUDE.md`** — Analytics config reference inside the
    `<!-- site-builder:start -->` marker block. Must reflect the analytics
    platforms installed and their verification status, as reported in
    `.site-builder/integration-reports/analytics.md`.
  ```

- [x] **Step 2:** Add a "Doc Gate Obligation" section to `agents/seo-indexing-agent.md`. Insert at the end of the file, after the "Output Format" section (after line 231).

  ```markdown
  ## Doc Gate Obligation

  After this agent completes, the orchestrator verifies the following docs
  per the agent-indexed mapping in `skills/site-builder/reference/doc-refresh.md`:

  - **`CLAUDE.md`** — Indexing config reference inside the
    `<!-- site-builder:start -->` marker block. Must reflect the IndexNow,
    RSS/Atom feed, and sitemap configuration, as reported in
    `.site-builder/integration-reports/seo-indexing.md`.
  ```

- [x] **Step 3:** Verify: analytics-agent obligation matches the mapping table row ("CLAUDE.md, analytics config reference"). SEO-indexing-agent obligation matches the mapping table row ("CLAUDE.md, indexing config reference").

- [x] **Step 4:** Commit: `docs(agents): add doc-gate obligations to analytics-agent and seo-indexing-agent`

---

## Phase 4 Complete

Six agent files now have explicit doc-gate obligations:
- `designer-agent.md` — BRAND.md (primary owner, all sections)
- `developer-agent.md` — ARCHITECTURE.md, CLAUDE.md, BRAND.md (verify-only). Stale `refresh-architecture.mjs` reference removed.
- `content-agent.md` — CONTEXT.md (Glossary)
- `social-integration-agent.md` — ARCHITECTURE.md (Integrations)
- `analytics-agent.md` — CLAUDE.md (analytics config reference)
- `seo-indexing-agent.md` — CLAUDE.md (indexing config reference)

**Note:** Three agents in the agent→doc mapping (discovery-agent, architect-agent,
deploy-agent) intentionally do NOT receive file-level "Doc Gate Obligation"
sections — their obligations are already covered by SKILL.md's Phase 1, 2,
and 9 Doc Gate entries (updated in Phase 3 Task 2). The spec's Modified files
list and AC-16–AC-21 only require the 6 agents modified above. If the spec's
testing strategy line ("grep each agent file for 'Doc Gate'") is applied
literally to all 9 mapped agents, 3 will not match — this is by design.

**Plan complete.**

### Verification Checklist (run after all phases)

| Check | Command | Expected |
|---|---|---|
| No "Doc refresh:" in SKILL.md | `grep -c "Doc refresh:" skills/site-builder/SKILL.md` | 0 |
| "Doc Gate:" in SKILL.md | `grep -c "Doc Gate:" skills/site-builder/SKILL.md` | 10 (phases 1–6, 8–11; not 7) |
| All 6 modified agents have "Doc Gate" | `grep -l "Doc Gate" agents/{designer,developer,content,social-integration,analytics,seo-indexing}-agent.md` | 6 files |
| No `refresh-architecture.mjs` reference | `grep -r "refresh-architecture" agents/` | 0 |
| Auto-marker consistency | `grep -roh 'auto:[a-z-]*' skills/site-builder/reference/ \| sort -u` | `auto:build-commands`, `auto:build-dev`, `auto:color-tokens`, `auto:dependencies`, `auto:directory-structure`, `auto:font-stack`, `auto:spacing-scale` |
| BRAND.md in Init 2.5 | `grep "BRAND.md" skills/site-builder/SKILL.md` | Present in Section 2.5 |
| Update Mode step count | Read `skills/site-builder/SKILL.md` Update Mode | 7 steps, Doc Refresh Gate at step 6 |
| phases.md Update Mode step count | Read `skills/site-builder/reference/phases.md` Update Mode | 7 steps (mirrors SKILL.md), Doc Refresh Gate at step 6 |
| Handoff checklist has BRAND.md | `grep "BRAND.md" skills/site-builder/reference/handoff-checklist.md` | Present |
| doc-refresh-script.sh is POSIX | Scan for `[[`, herestrings, bash arrays | None found |
