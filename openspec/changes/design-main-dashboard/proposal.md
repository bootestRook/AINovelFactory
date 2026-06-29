## Why

The app needs a real main dashboard that matches the reference layout while behaving correctly before any novel project exists. The dashboard must avoid fake demo data and present only actions and statistics backed by real local state.

## What Changes

- Add a Windows desktop main dashboard layout inspired by the reference: top app bar, welcome area, primary work card, statistics column, and novel project section.
- Add empty-state behavior for first use when no novel projects exist.
- Use real SQLite-backed data for novel counts, total word count, writing goal progress, recent writing project, and project list.
- Hide or replace project-dependent UI when there are no novel projects.
- Keep creation simple: direct `New Novel` and `Import Novel` actions only, with no onboarding wizard.
- Do not add placeholder novels, fake covers, demo statistics, or hardcoded business data.

## Capabilities

### New Capabilities

- `main-dashboard`: Defines the main dashboard layout, data-backed states, empty-state behavior, and primary user actions.

### Modified Capabilities

- None.

## Impact

- Affects the Flutter Windows desktop main interface.
- Requires querying local SQLite data for novels, word totals, recent writing state, and writing goals.
- May touch app navigation for `New Novel`, `Import Novel`, project opening, theme toggle, and AI settings entry points.
- No new third-party dependencies are expected.
