## Why

The current UI treats the novel workspace as a static writing panel, so users cannot tell which functional area they are in, what each menu item does, or which agents are involved. The product needs to behave like a novel creation workbench where creating a work, navigating story domains, and coordinating agents are explicit interactions.

## What Changes

- Add a secondary "new work" modal flow for creating or editing the current work.
- Turn the left navigation entries into functional workspace modules, not static labels.
- Keep the four-column workspace structure: tool rail, module tree, content pane, agent pane.
- Make the center pane render module-specific content, empty states, and actions.
- Make the right agent pane show relevant agents, enabled state, current agent context, and chat/planning controls.
- Keep engineering artifacts available only as secondary/debug detail, not as the default experience.

## Capabilities

### New Capabilities
- `work-creation-modal`: Covers creating a work through a modal with title, cover image, description, category, work type, and custom tags.
- `workspace-module-navigation`: Covers functional navigation for System, Creation, Setting, and AI modules, including module-specific content and actions.
- `agent-interaction-controls`: Covers selecting, enabling, disabling, inspecting, and chatting with agents from the workspace.

### Modified Capabilities

None.

## Impact

- Affects `src/App.tsx` and `src/index.css`.
- May add small local data models for work metadata, workspace modules, and agent bindings.
- No new runtime dependency is required.
- No backend or persistent file-system storage is required for this change.
