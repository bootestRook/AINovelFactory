## 1. Workspace Data Model

- [x] 1.1 Add a local module registry with group, id, label, description, actions, related agents, and sample records.
- [x] 1.2 Add work metadata state for title, cover image, description, category, type, and custom tags.
- [x] 1.3 Replace string-only active navigation with module-id based selection.

## 2. Work Creation Modal

- [x] 2.1 Keep "新建作品" as a modal flow over the workspace.
- [x] 2.2 Render fields for title, cover image, description, category, type, and tags.
- [x] 2.3 Preserve full cover image preview in a book-cover ratio without cropping.
- [x] 2.4 Save modal values into the current work header and close the modal.

## 3. Functional Module Navigation

- [x] 3.1 Render the four-column shell: tool rail, module tree, content pane, and agent pane.
- [x] 3.2 Map System modules to overview and relationship-graph content.
- [x] 3.3 Map Creation modules to chapters, outline, characters, and foreshadowing content.
- [x] 3.4 Map Setting modules to worldbuilding, map, forces, creatures, items, skills, and materials content.
- [x] 3.5 Map AI modules to chat, roundtable, monologue, skit, roleplay, agent planning, and agent skills content.
- [x] 3.6 Show module-specific actions and empty states in the content pane.

## 4. Agent Interaction Controls

- [x] 4.1 Show the current agent role, responsibilities, inputs, and outputs.
- [x] 4.2 Allow users to select the current agent.
- [x] 4.3 Allow users to enable and disable agents.
- [x] 4.4 Show module-relevant agents when the selected module changes.
- [x] 4.5 Add current-agent scoped chat input.
- [x] 4.6 Show agent planning controls for "智能体规划".

## 5. Verification

- [x] 5.1 Run `npm run check`.
- [x] 5.2 Run `npm run build`.
- [x] 5.3 Verify the app renders at `http://127.0.0.1:5173/`.
