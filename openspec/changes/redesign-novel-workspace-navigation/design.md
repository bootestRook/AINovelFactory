## Context

The current React UI is a prototype that has a four-column shell and a new-work modal, but most navigation entries still behave like labels. The intended product is a novel creation workspace where each left-side option opens a real work area and the agent pane reflects the current work context.

Constraints:
- Keep the frontend local and dependency-light.
- Do not add backend storage in this change.
- Keep engineering/debug artifacts secondary.
- Preserve the four-column mental model: tool rail, module tree, content pane, agent pane.

## Goals / Non-Goals

**Goals:**
- Make work creation a modal flow, not an inline page.
- Map each navigation entry to module metadata: title, purpose, related agents, empty state, and actions.
- Render module-specific content in the center pane.
- Let users see, select, enable, and disable agents from the right pane.
- Keep the default workspace focused while still exposing technical details on demand.

**Non-Goals:**
- No real LLM provider integration.
- No file-system artifact store.
- No graph rendering library.
- No persistent database or SQLite memory.
- No multi-user collaboration.

## Decisions

1. Use a local module registry.
   - Each module entry defines `group`, `id`, `label`, `description`, `actions`, `agentIds`, and optional sample records.
   - This is simpler than route-level state or a plugin system and enough for the current prototype.
   - Alternative considered: hard-code `contentFor(activeItem)` branches. Rejected because it keeps repeating the current "menu name only" problem.

2. Keep the new-work form as a modal.
   - The modal owns name, cover, intro, category, type, and custom tags.
   - The main workspace only shows the selected/current work.
   - Alternative considered: a full creation page. Rejected because user explicitly asked for a secondary window.

3. Treat agent controls as workspace state, not pipeline internals.
   - The UI can enable/disable and select agents before the backend truly honors partial execution.
   - The right pane must disclose which module uses which agents.
   - Alternative considered: hide agent controls until real orchestration exists. Rejected because agent transparency is a core UX requirement.

4. Keep debug artifacts behind a details drawer.
   - Intermediate artifacts remain inspectable but never dominate the default view.
   - Alternative considered: artifact browser as a primary panel. Rejected because it makes the writing environment noisy.

## Risks / Trade-offs

- Partial execution is visual-only at first -> Label this as planning/selection until orchestrator honors enabled agents.
- Module content is initially local sample data -> Use clear empty states and actions so later storage can replace arrays without redesigning UI.
- Object URLs for local cover previews can leak if unmanaged -> For this prototype the risk is small; revoke URLs when replacing/removing covers in a later hardening pass.
- Four columns may crowd smaller screens -> Collapse rail/sidebar/panes on small viewports.
